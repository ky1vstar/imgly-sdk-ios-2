//
//  IMGLYCameraController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 15/05/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation
import AVFoundation
import OpenGLES
import GLKit
import CoreMotion

struct IMGLYSDKVersion: Comparable, CustomStringConvertible {
    let majorVersion: Int
    let minorVersion: Int
    let patchVersion: Int
    
    var description: String {
        return "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}

func ==(lhs: IMGLYSDKVersion, rhs: IMGLYSDKVersion) -> Bool {
    return (lhs.majorVersion == rhs.majorVersion) && (lhs.minorVersion == rhs.minorVersion) && (lhs.patchVersion == rhs.patchVersion)
}

func <(lhs: IMGLYSDKVersion, rhs: IMGLYSDKVersion) -> Bool {
    if lhs.majorVersion < rhs.majorVersion {
        return true
    } else if lhs.majorVersion > rhs.majorVersion {
        return false
    }
    
    if lhs.minorVersion < rhs.minorVersion {
        return true
    } else if lhs.minorVersion > rhs.minorVersion {
        return false
    }
    
    if lhs.patchVersion < rhs.patchVersion {
        return true
    } else if lhs.patchVersion > rhs.patchVersion {
        return false
    }
    
    return false
}

let CurrentSDKVersion = IMGLYSDKVersion(majorVersion: 2, minorVersion: 4, patchVersion: 0)

private let kIMGLYIndicatorSize = CGFloat(75)
private var CapturingStillImageContext = 0
private var SessionRunningAndDeviceAuthorizedContext = 0
private var FocusAndExposureContext = 0

@objc public protocol IMGLYCameraControllerDelegate: class {
    @objc optional func cameraControllerDidStartCamera(_ cameraController: IMGLYCameraController)
    @objc optional func cameraControllerDidStopCamera(_ cameraController: IMGLYCameraController)
    @objc optional func cameraControllerDidStartStillImageCapture(_ cameraController: IMGLYCameraController)
    @objc optional func cameraControllerDidFailAuthorization(_ cameraController: IMGLYCameraController)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, didChangeToFlashMode flashMode: AVCaptureDevice.FlashMode)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, didChangeToTorchMode torchMode: AVCaptureDevice.TorchMode)
    @objc optional func cameraControllerDidCompleteSetup(_ cameraController: IMGLYCameraController)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, willSwitchToCameraPosition cameraPosition: AVCaptureDevice.Position)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, didSwitchToCameraPosition cameraPosition: AVCaptureDevice.Position)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, willSwitchToRecordingMode recordingMode: IMGLYRecordingMode)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, didSwitchToRecordingMode recordingMode: IMGLYRecordingMode)
    @objc optional func cameraControllerAnimateAlongsideFirstPhaseOfRecordingModeSwitchBlock(_ cameraController: IMGLYCameraController) -> (() -> Void)
    @objc optional func cameraControllerAnimateAlongsideSecondPhaseOfRecordingModeSwitchBlock(_ cameraController: IMGLYCameraController) -> (() -> Void)
    @objc optional func cameraControllerFirstPhaseOfRecordingModeSwitchAnimationCompletionBlock(_ cameraController: IMGLYCameraController) -> (() -> Void)
    @objc optional func cameraControllerDidStartRecording(_ cameraController: IMGLYCameraController)
    @objc optional func cameraController(_ cameraController: IMGLYCameraController, recordedSeconds seconds: Int)
    @objc optional func cameraControllerDidFinishRecording(_ cameraController: IMGLYCameraController, fileURL: URL)
    @objc optional func cameraControllerDidFailRecording(_ cameraController: IMGLYCameraController, error: NSError?)
}

public typealias IMGLYTakePhotoBlock = (UIImage?, Error?) -> Void
public typealias IMGLYRecordVideoBlock = (URL?, NSError?) -> Void

private let kTempVideoFilename = "recording.mov"

open class IMGLYCameraController: NSObject {
    
    // MARK: - Properties
    
    /// The response filter that is applied to the live-feed.
    open var effectFilter: IMGLYResponseFilter = IMGLYNoneFilter()
    public let previewView: UIView
    open var previewContentMode: UIView.ContentMode  = .scaleAspectFit

    open weak var delegate: IMGLYCameraControllerDelegate?
    public let tapGestureRecognizer = UITapGestureRecognizer()
    
    @objc dynamic fileprivate let session = AVCaptureSession()
    fileprivate let sessionQueue = DispatchQueue(label: "capture_session_queue", attributes: [])
    fileprivate var videoDeviceInput: AVCaptureDeviceInput?
    fileprivate var audioDeviceInput: AVCaptureDeviceInput?
    fileprivate var videoDataOutput: AVCaptureVideoDataOutput?
    fileprivate var audioDataOutput: AVCaptureAudioDataOutput?
    @objc dynamic fileprivate var stillImageOutput: AVCaptureStillImageOutput?
    fileprivate var runtimeErrorHandlingObserver: NSObjectProtocol?
    @objc dynamic fileprivate var deviceAuthorized = false
    fileprivate var glContext: EAGLContext?
    fileprivate var ciContext: CIContext?
    fileprivate var videoPreviewView: GLKView?
    fileprivate var setupComplete = false
    fileprivate var videoPreviewFrame = CGRect.zero
    fileprivate let focusIndicatorLayer = CALayer()
    fileprivate let maskIndicatorLayer = CALayer()
    fileprivate let upperMaskDarkenLayer = CALayer()
    fileprivate let lowerMaskDarkenLayer = CALayer()
    fileprivate var focusIndicatorFadeOutTimer: Timer?
    fileprivate var focusIndicatorAnimating = false
    fileprivate let motionManager: CMMotionManager = {
        let motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.2
        return motionManager
        }()
    fileprivate let motionManagerQueue = OperationQueue()
    fileprivate var captureVideoOrientation: AVCaptureVideoOrientation?
    
    @objc dynamic fileprivate var sessionRunningAndDeviceAuthorized: Bool {
        return session.isRunning && deviceAuthorized
    }
    
    open var squareMode: Bool
    
    // Video Recording
    fileprivate var assetWriter: AVAssetWriter?
    fileprivate var assetWriterAudioInput: AVAssetWriterInput?
    fileprivate var assetWriterVideoInput: AVAssetWriterInput?
    fileprivate var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    fileprivate var currentVideoDimensions: CMVideoDimensions?
    fileprivate var currentAudioSampleBufferFormatDescription: CMFormatDescription?
    fileprivate var backgroundRecordingID: UIBackgroundTaskIdentifier?
    fileprivate var videoWritingStarted = false
    fileprivate var videoWritingStartTime: CMTime?
    fileprivate var currentVideoTime: CMTime?
    fileprivate var timeUpdateTimer: Timer?
    open var maximumVideoLength: Int?
    
    // MARK: - Initializers
    
    init(previewView: UIView) {
        self.previewView = previewView
        self.squareMode = false
        super.init()
    }
    
    // MARK: - NSKeyValueObserving
    
    @objc class func keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized() -> Set<String> {
        return Set(["session.running", "deviceAuthorized"])
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &CapturingStillImageContext {
            let capturingStillImage = (change?[NSKeyValueChangeKey.newKey] as AnyObject).boolValue
            
            if let isCapturingStillImage = capturingStillImage, isCapturingStillImage {
                self.delegate?.cameraControllerDidStartStillImageCapture?(self)
            }
        } else if context == &SessionRunningAndDeviceAuthorizedContext {
            let running = (change?[NSKeyValueChangeKey.newKey] as AnyObject).boolValue
            
            if let isRunning = running {
                if isRunning {
                    self.delegate?.cameraControllerDidStartCamera?(self)
                } else {
                    self.delegate?.cameraControllerDidStopCamera?(self)
                }
            }
        } else if context == &FocusAndExposureContext {
            DispatchQueue.main.async {
                self.updateFocusIndicatorLayer()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - SDK
    
    fileprivate func versionComponentsFromString(_ version: String) -> (majorVersion: Int, minorVersion: Int, patchVersion: Int)? {
        let versionComponents = version.components(separatedBy: ".")
        if versionComponents.count == 3 {
            if let major = Int(versionComponents[0]), let minor = Int(versionComponents[1]), let patch = Int(versionComponents[2]) {
                return (major, minor, patch)
            }
        }
        
        return nil
    }
    
    fileprivate func checkSDKVersion() {
        let appIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
        if let appIdentifier = appIdentifier, let url = URL(string: "https://photoeditorsdk.com/version.json?type=ios&app=\(appIdentifier)") {
            let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                        
                        if let json = json, let version = json["version"] as? String, let versionComponents = self.versionComponentsFromString(version) {
                            let remoteVersion = IMGLYSDKVersion(majorVersion: versionComponents.majorVersion, minorVersion: versionComponents.minorVersion, patchVersion: versionComponents.patchVersion)
                            
                            if CurrentSDKVersion < remoteVersion {
                                print("Your version of the img.ly SDK is outdated. You are using version \(CurrentSDKVersion), the latest available version is \(remoteVersion). Please consider updating.")
                            }
                        }
                    } catch {
                        
                    }
                }
            }) 
            
            task.resume()
        }
    }
    
    // MARK: - Authorization
    
    open func checkDeviceAuthorizationStatus() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
            if granted {
                self.deviceAuthorized = true
            } else {
                self.delegate?.cameraControllerDidFailAuthorization?(self)
                self.deviceAuthorized = false
            }
        })
    }
    
    // MARK: - Camera
    
    /// Use this property to determine if more than one camera is available. Within the SDK this property is used to determine if the toggle button is visible.
    open var moreThanOneCameraPresent: Bool {
        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        return videoDevices.count > 1
    }
    
    open func toggleCameraPosition() {
        if let device = videoDeviceInput?.device {
            let nextPosition: AVCaptureDevice.Position
            
            switch (device.position) {
            case .front:
                nextPosition = .back
            case .back:
                nextPosition = .front
            default:
                nextPosition = .back
            }
            
            delegate?.cameraController?(self, willSwitchToCameraPosition: nextPosition)
            focusIndicatorLayer.isHidden = true
            
            let sessionGroup = DispatchGroup()
            
            if let videoPreviewView = videoPreviewView {
                let (snapshotWithBlur, snapshot) = addSnapshotViewsToVideoPreviewView(videoPreviewView)
                
                // Transitioning between the regular snapshot and the blurred snapshot, this automatically removes `snapshot` and adds `snapshotWithBlur` to the view hierachy
                UIView.transition(from: snapshot, to: snapshotWithBlur, duration: 0.4, options: [.transitionFlipFromLeft, .curveEaseOut], completion: { _ in
                    // Wait for camera to toggle
                    sessionGroup.notify(queue: DispatchQueue.main) {
                        // Giving the preview view a bit of time to redraw first
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.05 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                            // Cross fading between blur and live preview, this sets `snapshotWithBlur.hidden` to `true` and `videoPreviewView.hidden` to false
                            UIView.transition(from: snapshotWithBlur, to: videoPreviewView, duration: 0.2, options: [.transitionCrossDissolve, .showHideTransitionViews], completion: { _ in
                                // Deleting the blurred snapshot
                                snapshotWithBlur.removeFromSuperview()
                            })
                        }
                    }
                })
            }
            
            sessionQueue.async {
                sessionGroup.enter()
                self.session.beginConfiguration()
                self.session.removeInput(self.videoDeviceInput!)
                
                self.removeObserversFromInputDevice()
                self.setupVideoInputsForPreferredCameraPosition(nextPosition)
                self.addObserversToInputDevice()
                
                self.session.commitConfiguration()
                sessionGroup.leave()
                
                self.delegate?.cameraController?(self, didSwitchToCameraPosition: nextPosition)
            }
        }
    }
    
    // MARK: - Mask layer
    fileprivate func setupMaskLayers() {
        setupMaskIndicatorLayer()
        setupUpperMaskDarkenLayer()
        setupLowerMaskDarkenLayer()
    }
    
    fileprivate func setupMaskIndicatorLayer() {
        maskIndicatorLayer.borderColor = UIColor.white.cgColor
        maskIndicatorLayer.borderWidth = 1
        maskIndicatorLayer.frame.origin = CGPoint(x: 0, y: 0)
        maskIndicatorLayer.frame.size = CGSize(width: kIMGLYIndicatorSize, height: kIMGLYIndicatorSize)
        maskIndicatorLayer.isHidden = true
        maskIndicatorLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        previewView.layer.addSublayer(maskIndicatorLayer)
    }
    
    fileprivate func setupUpperMaskDarkenLayer() {
        upperMaskDarkenLayer.borderWidth = 0
        upperMaskDarkenLayer.frame.origin = CGPoint(x: 0, y: 0)
        upperMaskDarkenLayer.frame.size = CGSize(width: kIMGLYIndicatorSize, height: kIMGLYIndicatorSize)
        upperMaskDarkenLayer.isHidden = true
        upperMaskDarkenLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        upperMaskDarkenLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.8).cgColor
        previewView.layer.addSublayer(upperMaskDarkenLayer)
    }

    fileprivate func setupLowerMaskDarkenLayer() {
        lowerMaskDarkenLayer.borderWidth = 0
        lowerMaskDarkenLayer.frame.origin = CGPoint(x: 0, y: 0)
        lowerMaskDarkenLayer.frame.size = CGSize(width: kIMGLYIndicatorSize, height: kIMGLYIndicatorSize)
        lowerMaskDarkenLayer.isHidden = true
        lowerMaskDarkenLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        lowerMaskDarkenLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.8).cgColor
        previewView.layer.addSublayer(lowerMaskDarkenLayer)
    }
    
    
    // MARK: - Square view 
    
    /*
    Please note, the calculations in this method might look a bit weird.
    The reason is that the frame we are getting is rotated by 90 degree
    */
    fileprivate func updateSquareIndicatorView(_ newRect: CGRect) {
        let width = newRect.size.height / 2.0
        let height = width
        let top = newRect.origin.x + ((newRect.size.width / 2.0) - width) / 2.0
        let left = newRect.origin.y / 2.0
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        maskIndicatorLayer.frame = CGRect(x: left, y: top, width: width, height: height).integral
        upperMaskDarkenLayer.frame = CGRect(x: left, y: 0, width: width, height: top - 1).integral
        // add extra space to the bottom to avoid a gab due to the lower bar animation
        lowerMaskDarkenLayer.frame = CGRect(x: left, y: top + height + 1, width: width, height: top * 2).integral
        CATransaction.commit()
    }
    
    open func showSquareMask() {
        maskIndicatorLayer.isHidden = false
        upperMaskDarkenLayer.isHidden = false
        lowerMaskDarkenLayer.isHidden = false
    }
    
    open func hideSquareMask() {
        maskIndicatorLayer.isHidden = true
        upperMaskDarkenLayer.isHidden = true
        lowerMaskDarkenLayer.isHidden = true
    }
    
    // MARK: - Flash
    
    /**
    Selects the next flash-mode. The order is Auto->On->Off.
    If the current device does not support auto-flash, this method
    just toggles between on and off.
    */
    open func selectNextFlashMode() {
        var nextFlashMode: AVCaptureDevice.FlashMode = .off
        
        switch flashMode {
        case .auto:
            if let device = videoDeviceInput?.device, device.isFlashModeSupported(.on) {
                nextFlashMode = .on
            }
        case .on:
            nextFlashMode = .off
        case .off:
            if let device = videoDeviceInput?.device {
                if device.isFlashModeSupported(.auto) {
                    nextFlashMode = .auto
                } else if device.isFlashModeSupported(.on) {
                    nextFlashMode = .on
                }
            }
        default:
            break
        }
        
        flashMode = nextFlashMode
    }
    
    open fileprivate(set) var flashMode: AVCaptureDevice.FlashMode {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.flashMode
            } else {
                return .off
            }
        }
        
        set {
            sessionQueue.async {
                var error: NSError?
                self.session.beginConfiguration()
                
                if let device = self.videoDeviceInput?.device {
                    do {
                        try device.lockForConfiguration()
                    } catch let error1 as NSError {
                        error = error1
                    } catch {
                        fatalError()
                    }
                    device.flashMode = newValue
                    device.unlockForConfiguration()
                }
                
                self.session.commitConfiguration()
                
                if let error = error {
                    print("Error changing flash mode: \(error.description)")
                    return
                }
                
                self.delegate?.cameraController?(self, didChangeToFlashMode: newValue)
            }
        }
    }
    
    // MARK: - Torch
    
    /**
    Selects the next torch-mode. The order is Auto->On->Off.
    If the current device does not support auto-torch, this method
    just toggles between on and off.
    */
    open func selectNextTorchMode() {
        var nextTorchMode: AVCaptureDevice.TorchMode = .off
        
        switch torchMode {
        case .auto:
            if let device = videoDeviceInput?.device, device.isTorchModeSupported(.on) {
                nextTorchMode = .on
            }
        case .on:
            nextTorchMode = .off
        case .off:
            if let device = videoDeviceInput?.device {
                if device.isTorchModeSupported(.auto) {
                    nextTorchMode = .auto
                } else if device.isTorchModeSupported(.on) {
                    nextTorchMode = .on
                }
            }
        default:
            break
        }
        
        torchMode = nextTorchMode
    }
    
    open fileprivate(set) var torchMode: AVCaptureDevice.TorchMode {
        get {
            if let device = self.videoDeviceInput?.device {
                return device.torchMode
            } else {
                return .off
            }
        }
        
        set {
            sessionQueue.async {
                var error: NSError?
                self.session.beginConfiguration()
                
                if let device = self.videoDeviceInput?.device {
                    do {
                        try device.lockForConfiguration()
                    } catch let error1 as NSError {
                        error = error1
                    } catch {
                        fatalError()
                    }
                    device.torchMode = newValue
                    device.unlockForConfiguration()
                }
                
                self.session.commitConfiguration()
                
                if let error = error {
                    print("Error changing torch mode: \(error.description)")
                    return
                }
                
                self.delegate?.cameraController?(self, didChangeToTorchMode: newValue)
            }
        }
    }
    
    // MARK: - Focus
    
    fileprivate func setupFocusIndicator() {
        focusIndicatorLayer.borderColor = UIColor.white.cgColor
        focusIndicatorLayer.borderWidth = 1
        focusIndicatorLayer.frame.size = CGSize(width: kIMGLYIndicatorSize, height: kIMGLYIndicatorSize)
        focusIndicatorLayer.isHidden = true
        focusIndicatorLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        previewView.layer.addSublayer(focusIndicatorLayer)
        
        tapGestureRecognizer.addTarget(self, action: #selector(IMGLYCameraController.tapped(_:)))
        
        if let videoPreviewView = videoPreviewView {
            videoPreviewView.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    fileprivate func showFocusIndicatorLayerAtLocation(_ location: CGPoint) {
        focusIndicatorFadeOutTimer?.invalidate()
        focusIndicatorFadeOutTimer = nil
        focusIndicatorAnimating = false
        
        CATransaction.begin()
        focusIndicatorLayer.opacity = 1
        focusIndicatorLayer.isHidden = false
        focusIndicatorLayer.borderColor = UIColor.white.cgColor
        focusIndicatorLayer.frame.size = CGSize(width: kIMGLYIndicatorSize, height: kIMGLYIndicatorSize)
        focusIndicatorLayer.position = location
        focusIndicatorLayer.transform = CATransform3DIdentity
        focusIndicatorLayer.removeAllAnimations()
        CATransaction.commit()
        
        let resizeAnimation = CABasicAnimation(keyPath: "transform")
        resizeAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(1.5, 1.5, 1))
        resizeAnimation.duration = 0.25
        focusIndicatorLayer.add(resizeAnimation, forKey: nil)
    }
    
    @objc fileprivate func tapped(_ recognizer: UITapGestureRecognizer) {
        if focusPointSupported || exposurePointSupported {
            if let videoPreviewView = videoPreviewView {
                let focusPointLocation = recognizer.location(in: videoPreviewView)
                let scaleFactor = videoPreviewView.contentScaleFactor
                let videoFrame = CGRect(x: videoPreviewFrame.minX / scaleFactor, y: videoPreviewFrame.minY / scaleFactor, width: videoPreviewFrame.width / scaleFactor, height: videoPreviewFrame.height / scaleFactor)
                
                if videoFrame.contains(focusPointLocation) {
                    let focusIndicatorLocation = recognizer.location(in: previewView)
                    showFocusIndicatorLayerAtLocation(focusIndicatorLocation)
                    
                    var pointOfInterest = CGPoint(x: focusPointLocation.x / videoFrame.width, y: focusPointLocation.y / videoFrame.height)
                    pointOfInterest.x = 1 - pointOfInterest.x
                    
                    if let device = videoDeviceInput?.device, device.position == .front {
                        pointOfInterest.y = 1 - pointOfInterest.y
                    }
                    
                    focusWithMode(.autoFocus, exposeWithMode: .autoExpose, atDevicePoint: pointOfInterest, monitorSubjectAreaChange: true)
                }
            }
        }
    }
    
    fileprivate var focusPointSupported: Bool {
        if let device = videoDeviceInput?.device {
            return device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) && device.isFocusModeSupported(.continuousAutoFocus)
        }
        
        return false
    }
    
    fileprivate var exposurePointSupported: Bool {
        if let device = videoDeviceInput?.device {
            return device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) && device.isExposureModeSupported(.continuousAutoExposure)
        }
        
        return false
    }
    
    fileprivate func focusWithMode(_ focusMode: AVCaptureDevice.FocusMode, exposeWithMode exposureMode: AVCaptureDevice.ExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            if let device = self.videoDeviceInput?.device {
                var error: NSError?
                
                do {
                    try device.lockForConfiguration()
                    if self.focusPointSupported {
                        device.focusMode = focusMode
                        device.focusPointOfInterest = point
                    }
                    
                    if self.exposurePointSupported {
                        device.exposureMode = exposureMode
                        device.exposurePointOfInterest = point
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                } catch let error1 as NSError {
                    error = error1
                    print("Error in focusWithMode:exposeWithMode:atDevicePoint:monitorSubjectAreaChange: \(String(describing: error?.description))")
                } catch {
                    fatalError()
                }
                
            }
        }
    }
    
    fileprivate func updateFocusIndicatorLayer() {
        if let device = videoDeviceInput?.device {
            if focusIndicatorLayer.isHidden == false {
                if device.focusMode == .locked && device.exposureMode == .locked {
                    focusIndicatorLayer.borderColor = UIColor(white: 1, alpha: 0.5).cgColor
                }
            }
        }
    }
    
    @objc fileprivate func subjectAreaDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.disableFocusLockAnimated(true)
        }
    }
    
    open func disableFocusLockAnimated(_ animated: Bool) {
        if focusIndicatorAnimating {
            return
        }
        
        focusIndicatorAnimating = true
        focusIndicatorFadeOutTimer?.invalidate()
        
        if focusPointSupported || exposurePointSupported {
            focusWithMode(.continuousAutoFocus, exposeWithMode: .continuousAutoExposure, atDevicePoint: CGPoint(x: 0.5, y: 0.5), monitorSubjectAreaChange: false)
            
            if animated {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                focusIndicatorLayer.borderColor = UIColor.white.cgColor
                focusIndicatorLayer.frame.size = CGSize(width: kIMGLYIndicatorSize * 2, height: kIMGLYIndicatorSize * 2)
                focusIndicatorLayer.transform = CATransform3DIdentity
                focusIndicatorLayer.position = previewView.center
                
                CATransaction.commit()
                
                let resizeAnimation = CABasicAnimation(keyPath: "transform")
                resizeAnimation.duration = 0.25
                resizeAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(1.5, 1.5, 1))
                resizeAnimation.delegate = IMGLYAnimationDelegate(block: { finished in
                    if finished {
                        self.focusIndicatorFadeOutTimer = Timer.after(0.85) { [unowned self] in
                            self.focusIndicatorLayer.opacity = 0
                            
                            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                            fadeAnimation.duration = 0.25
                            fadeAnimation.fromValue = 1
                            fadeAnimation.delegate = IMGLYAnimationDelegate(block: { finished in
                                if finished {
                                    CATransaction.begin()
                                    CATransaction.setDisableActions(true)
                                    self.focusIndicatorLayer.isHidden = true
                                    self.focusIndicatorLayer.opacity = 1
                                    self.focusIndicatorLayer.frame.size = CGSize(width: kIMGLYIndicatorSize, height: kIMGLYIndicatorSize)
                                    CATransaction.commit()
                                    self.focusIndicatorAnimating = false
                                }
                            })
                            
                            self.focusIndicatorLayer.add(fadeAnimation, forKey: nil)
                        }
                    }
                })
                
                focusIndicatorLayer.add(resizeAnimation, forKey: nil)
            } else {
                focusIndicatorLayer.isHidden = true
                focusIndicatorAnimating = false
            }
        } else {
            focusIndicatorLayer.isHidden = true
            focusIndicatorAnimating = false
        }
    }
    
    // MARK: - Capture Session
    
    open func setup() {
        // For backwards compatibility
        setupWithInitialRecordingMode(.photo)
    }
    
    /**
    Initializes the camera and has to be called before calling `startCamera()` / `stopCamera()`
    */
    open func setupWithInitialRecordingMode(_ recordingMode: IMGLYRecordingMode) {
        if setupComplete {
            return
        }
        
        checkSDKVersion()
        checkDeviceAuthorizationStatus()
        
        guard let glContext = EAGLContext(api: .openGLES2) else {
            return
        }
        
        videoPreviewView = GLKView(frame: CGRect.zero, context: glContext)
        videoPreviewView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoPreviewView!.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        videoPreviewView!.frame = previewView.bounds
        
        previewView.addSubview(videoPreviewView!)
        previewView.sendSubviewToBack(videoPreviewView!)
        
        ciContext = CIContext(eaglContext: glContext)
        videoPreviewView!.bindDrawable()
        
        setupWithPreferredCameraPosition(.back) {
            if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: recordingMode.sessionPreset)) {
                self.session.sessionPreset = AVCaptureSession.Preset(rawValue: recordingMode.sessionPreset)
            }
            
            if let device = self.videoDeviceInput?.device {
                if recordingMode == .photo && device.isFlashModeSupported(.auto) {
                    self.flashMode = .auto
                } else if recordingMode == .video && device.isTorchModeSupported(.auto) {
                    self.torchMode = .auto
                }
            }
            
            self.delegate?.cameraControllerDidCompleteSetup?(self)
        }
        
        setupFocusIndicator()
        setupMaskLayers()
        
        setupComplete = true
    }
    
    open func switchToRecordingMode(_ recordingMode: IMGLYRecordingMode) {
        switchToRecordingMode(recordingMode, animated: true)
    }
    
    open func switchToRecordingMode(_ recordingMode: IMGLYRecordingMode, animated: Bool) {
        delegate?.cameraController?(self, willSwitchToRecordingMode: recordingMode)
        
        focusIndicatorLayer.isHidden = true
        
        let sessionGroup = DispatchGroup()
        
        if let videoPreviewView = videoPreviewView {
            let (snapshotWithBlur, snapshot) = addSnapshotViewsToVideoPreviewView(videoPreviewView)
            
            UIView.animate(withDuration: animated ? 0.4 : 0, delay: 0, options: .curveEaseOut, animations: {
                // Transitioning between the regular snapshot and the blurred snapshot, this automatically removes `snapshot` and adds `snapshotWithBlur` to the view hierachy
                UIView.transition(from: snapshot, to: snapshotWithBlur, duration: 0, options: .transitionCrossDissolve, completion: nil)
                self.delegate?.cameraControllerAnimateAlongsideFirstPhaseOfRecordingModeSwitchBlock?(self)()
                }) { _ in
                    self.delegate?.cameraControllerFirstPhaseOfRecordingModeSwitchAnimationCompletionBlock?(self)()
                    // Wait for mode switch
                    sessionGroup.notify(queue: DispatchQueue.main) {
                        // Giving the preview view a bit of time to redraw first
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64((animated ? 0.05 : 0) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                            UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
                                // Cross fading between blur and live preview, this sets `snapshotWithBlur.hidden` to `true` and `videoPreviewView.hidden` to false
                                UIView.transition(from: snapshotWithBlur, to: videoPreviewView, duration: 0, options: [.transitionCrossDissolve, .showHideTransitionViews], completion: nil)
                                self.delegate?.cameraControllerAnimateAlongsideSecondPhaseOfRecordingModeSwitchBlock?(self)()
                                }, completion: { _ in
                                    // Deleting the blurred snapshot
                                    snapshotWithBlur.removeFromSuperview()
                            }) 
                        }
                    }
            }
        }
        
        sessionQueue.async {
            sessionGroup.enter()
            if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: recordingMode.sessionPreset)) {
                self.session.sessionPreset = AVCaptureSession.Preset(rawValue: recordingMode.sessionPreset)
            }
            sessionGroup.leave()

            switch(recordingMode) {
            case .photo:
                if self.flashAvailable {
                    self.flashMode = AVCaptureDevice.FlashMode(rawValue: self.torchMode.rawValue)!
                    self.torchMode = .off
                }
            case .video:
                if self.torchAvailable {
                    self.torchMode = AVCaptureDevice.TorchMode(rawValue: self.flashMode.rawValue)!
                    self.flashMode = .off
                }
            }
            
            self.delegate?.cameraController?(self, didSwitchToRecordingMode: recordingMode)
        }
    }
    
    fileprivate func setupWithPreferredCameraPosition(_ cameraPosition: AVCaptureDevice.Position, completion: (() -> (Void))?) {
        sessionQueue.async {
            self.setupVideoInputsForPreferredCameraPosition(cameraPosition)
            self.setupAudioInputs()
            self.setupOutputs()
            
            completion?()
        }
    }
    
    fileprivate func setupVideoInputsForPreferredCameraPosition(_ cameraPosition: AVCaptureDevice.Position) {
        var error: NSError?
        
        let videoDevice = IMGLYCameraController.deviceWithMediaType(AVMediaType.video.rawValue, preferringPosition: cameraPosition)
        let videoDeviceInput: AVCaptureDeviceInput!
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch let error1 as NSError {
            error = error1
            videoDeviceInput = nil
        }
        
        if let error = error {
            print("Error in setupVideoInputsForPreferredCameraPosition: \(error.description)")
        }
        
        if self.session.canAddInput(videoDeviceInput) {
            self.session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            
            DispatchQueue.main.async {
                if let videoPreviewView = self.videoPreviewView, let device = videoDevice {
                    if device.position == .front {
                        // front camera is mirrored so we need to transform the preview view
                        videoPreviewView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
                        videoPreviewView.transform = videoPreviewView.transform.scaledBy(x: 1, y: -1)
                    } else {
                        videoPreviewView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
                    }
                }
            }
        }
    }
    
    fileprivate func setupAudioInputs() {
        var error: NSError?
        
        let audioDevice = IMGLYCameraController.deviceWithMediaType(AVMediaType.audio.rawValue, preferringPosition: nil)
        let audioDeviceInput: AVCaptureDeviceInput!
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
        } catch let error1 as NSError {
            error = error1
            audioDeviceInput = nil
        }
        
        if let error = error {
            print("Error in setupAudioInputs: \(error.description)")
        }
        
        if self.session.canAddInput(audioDeviceInput) {
            self.session.addInput(audioDeviceInput)
            self.audioDeviceInput = audioDeviceInput
        }
    }
    
    fileprivate func setupOutputs() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        if self.session.canAddOutput(videoDataOutput) {
            self.session.addOutput(videoDataOutput)
            self.videoDataOutput = videoDataOutput
        }
        
        if audioDeviceInput != nil {
            let audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.session.canAddOutput(audioDataOutput) {
                self.session.addOutput(audioDataOutput)
                self.audioDataOutput = audioDataOutput
            }
        }
        
        let stillImageOutput = AVCaptureStillImageOutput()
        if self.session.canAddOutput(stillImageOutput) {
            self.session.addOutput(stillImageOutput)
            self.stillImageOutput = stillImageOutput
        }
    }
    
    /**
    Starts the camera preview.
    */
    open func startCamera() {
        assert(setupComplete, "setup() needs to be called before calling startCamera()")
        
        if session.isRunning {
            return
        }
        
        startCameraWithCompletion(nil)
        
        // Used to determine device orientation even if orientation lock is active
        motionManager.startAccelerometerUpdates(to: motionManagerQueue, withHandler: { accelerometerData, _ in
            guard let accelerometerData = accelerometerData else {
                return
            }
            
            if abs(accelerometerData.acceleration.y) < abs(accelerometerData.acceleration.x) {
                if accelerometerData.acceleration.x > 0 {
                    self.captureVideoOrientation = .landscapeLeft
                } else {
                    self.captureVideoOrientation = .landscapeRight
                }
            } else {
                if accelerometerData.acceleration.y > 0 {
                    self.captureVideoOrientation = .portraitUpsideDown
                } else {
                    self.captureVideoOrientation = .portrait
                }
            }
        })
    }
    
    fileprivate func startCameraWithCompletion(_ completion: (() -> (Void))?) {
        sessionQueue.async {
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.old, .new], context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options: [.old, .new], context: &CapturingStillImageContext)
            
            self.addObserversToInputDevice()
            
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.session, queue: nil, using: { [unowned self] _ in
                self.sessionQueue.async {
                    self.session.startRunning()
                }
                })
            
            self.session.startRunning()
            completion?()
        }
    }
    
    fileprivate func addObserversToInputDevice() {
        if let device = self.videoDeviceInput?.device {
            device.addObserver(self, forKeyPath: "focusMode", options: [.old, .new], context: &FocusAndExposureContext)
            device.addObserver(self, forKeyPath: "exposureMode", options: [.old, .new], context: &FocusAndExposureContext)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(IMGLYCameraController.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
    }
    
    fileprivate func removeObserversFromInputDevice() {
        if let device = self.videoDeviceInput?.device {
            device.removeObserver(self, forKeyPath: "focusMode", context: &FocusAndExposureContext)
            device.removeObserver(self, forKeyPath: "exposureMode", context: &FocusAndExposureContext)
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
    }
    
    /**
    Stops the camera preview.
    */
    open func stopCamera() {
        assert(setupComplete, "setup() needs to be called before calling stopCamera()")
        
        if !session.isRunning {
            return
        }
        
        stopCameraWithCompletion(nil)
        motionManager.stopAccelerometerUpdates()
    }
    
    fileprivate func stopCameraWithCompletion(_ completion: (() -> (Void))?) {
        sessionQueue.async {
            self.session.stopRunning()
            
            self.removeObserversFromInputDevice()
            
            if let runtimeErrorHandlingObserver = self.runtimeErrorHandlingObserver {
                NotificationCenter.default.removeObserver(runtimeErrorHandlingObserver)
            }
            
            self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
            self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
            completion?()
        }
    }
    
    /// Check if the current device has a flash.
    open var flashAvailable: Bool {
        if let device = self.videoDeviceInput?.device {
            return device.isFlashAvailable
        }
        
        return false
    }
    
    /// Check if the current device has a torch.
    open var torchAvailable: Bool {
        if let device = self.videoDeviceInput?.device {
            return device.isTorchAvailable
        }
        
        return false
    }
    
    // MARK: - Still Image Capture
    
    open func squareTakenImage(_ image:UIImage) -> UIImage {
        let stack = IMGLYFixedFilterStack()
        var scale = (image.size.width / image.size.height)
        if let captureVideoOrientation = self.captureVideoOrientation {
            if captureVideoOrientation == .landscapeRight || captureVideoOrientation == .landscapeLeft {
                scale = (image.size.height / image.size.width)
            }
        }
        let offset = (1.0 - scale) / 2.0
        stack.orientationCropFilter.cropRect = CGRect(x: offset, y: 0, width: scale, height: 1.0)
        return IMGLYPhotoProcessor.processWithUIImage(image, filters: stack.activeFilters)!
    }
    
    /**
    Takes a photo and hands it over to the completion block.
    
    - parameter completion: A completion block that has an image and an error as parameters.
    If the image was taken sucessfully the error is nil.
    */
    open func takePhoto(_ completion: @escaping IMGLYTakePhotoBlock) {
        if let stillImageOutput = self.stillImageOutput {
            sessionQueue.async {
                let connection = stillImageOutput.connection(with: AVMediaType.video)
                
                // Update the orientation on the still image output video connection before capturing.
                if let captureVideoOrientation = self.captureVideoOrientation {
                    connection?.videoOrientation = captureVideoOrientation
                }
                
                stillImageOutput.captureStillImageAsynchronously(from: connection!) {
                    (imageDataSampleBuffer: CMSampleBuffer?, error: Error?) -> Void in
                    
                    if let imageDataSampleBuffer = imageDataSampleBuffer, let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer), var image = UIImage(data: imageData) {
                        
                        if self.squareMode {
                            image = self.squareTakenImage(image)
                        }
                        completion(image, nil)
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    // MARK: - Video Capture
    
    /**
    Starts recording a video.
    */
    open func startVideoRecording() {
        if assetWriter == nil {
            startWriting()
        }
    }
    
    /**
    Stop recording a video.
    */
    open func stopVideoRecording() {
        if assetWriter != nil {
            stopWriting()
        }
    }
    
    fileprivate func startWriting() {
        delegate?.cameraControllerDidStartRecording?(self)
        
        sessionQueue.async {
            var error: NSError?
            
            let outputFileURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(kTempVideoFilename))
            do {
                try FileManager.default.removeItem(at: outputFileURL)
            } catch _ {
            }
            
            let newAssetWriter: AVAssetWriter!
            do {
                newAssetWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mov)
            } catch let error1 as NSError {
                error = error1
                newAssetWriter = nil
            } catch {
                fatalError()
            }
            
            if newAssetWriter == nil || error != nil {
                self.delegate?.cameraControllerDidFailRecording?(self, error: error)
                return
            }
            
            let videoCompressionSettings = self.videoDataOutput?.recommendedVideoSettingsForAssetWriter(writingTo: AVFileType.mov)
            self.assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoCompressionSettings as [String: AnyObject]?)
            self.assetWriterVideoInput!.expectsMediaDataInRealTime = true
            
            var sourcePixelBufferAttributes: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA as UInt32), String(kCVPixelFormatOpenGLESCompatibility): kCFBooleanTrue]
            if let currentVideoDimensions = self.currentVideoDimensions {
                sourcePixelBufferAttributes[String(kCVPixelBufferWidthKey)] = NSNumber(value: currentVideoDimensions.width as Int32)
                sourcePixelBufferAttributes[String(kCVPixelBufferHeightKey)] = NSNumber(value: currentVideoDimensions.height as Int32)
            }
            
            self.assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.assetWriterVideoInput!, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
            
            if let videoDevice = self.videoDeviceInput?.device, let captureVideoOrientation = self.captureVideoOrientation {
                if videoDevice.position == .front {
                    self.assetWriterVideoInput?.transform = GetTransformForDeviceOrientation(captureVideoOrientation, mirrored: true)
                } else {
                    self.assetWriterVideoInput?.transform = GetTransformForDeviceOrientation(captureVideoOrientation)
                }
            }
            
            let canAddInput = newAssetWriter.canAdd(self.assetWriterVideoInput!)
            if !canAddInput {
                self.assetWriterAudioInput = nil
                self.assetWriterVideoInput = nil
                self.delegate?.cameraControllerDidFailRecording?(self, error: nil)
                return
            }
            
            newAssetWriter.add(self.assetWriterVideoInput!)
            
            if self.audioDeviceInput != nil {
                let audioCompressionSettings = self.audioDataOutput?.recommendedAudioSettingsForAssetWriter(writingTo: AVFileType.mov) as? [String: AnyObject]
                
                if newAssetWriter.canApply(outputSettings: audioCompressionSettings, forMediaType: AVMediaType.audio) {
                    self.assetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioCompressionSettings)
                    self.assetWriterAudioInput?.expectsMediaDataInRealTime = true
                    
                    if newAssetWriter.canAdd(self.assetWriterAudioInput!) {
                        newAssetWriter.add(self.assetWriterAudioInput!)
                    }
                }
            }
            
            if UIDevice.current.isMultitaskingSupported {
                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
            }
            
            self.videoWritingStarted = false
            self.assetWriter = newAssetWriter
            self.startTimeUpdateTimer()
        }
    }
    
    fileprivate func abortWriting() {
        if let assetWriter = assetWriter {
            assetWriter.cancelWriting()
            assetWriterAudioInput = nil
            assetWriterVideoInput = nil
            videoWritingStartTime = nil
            currentVideoTime = nil
            self.assetWriter = nil
            stopTimeUpdateTimer()
            
            // Remove temporary file
            let fileURL = assetWriter.outputURL
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch _ {
            }
            
            // End background task
            if let backgroundRecordingID = backgroundRecordingID, UIDevice.current.isMultitaskingSupported {
                UIApplication.shared.endBackgroundTask(backgroundRecordingID)
            }
            
            self.delegate?.cameraControllerDidFailRecording?(self, error: nil)
        }
    }
    
    fileprivate func stopWriting() {
        if let assetWriter = assetWriter {
            assetWriterAudioInput = nil
            assetWriterVideoInput = nil
            videoWritingStartTime = nil
            currentVideoTime = nil
            assetWriterInputPixelBufferAdaptor = nil
            self.assetWriter = nil
            
            sessionQueue.async {
                let fileURL = assetWriter.outputURL
                
                if assetWriter.status == .unknown {
                    self.delegate?.cameraControllerDidFailRecording?(self, error: nil)
                    return
                }
                
                assetWriter.finishWriting {
                    self.stopTimeUpdateTimer()
                    
                    if assetWriter.status == .failed {
                        DispatchQueue.main.async {
                            if let backgroundRecordingID = self.backgroundRecordingID {
                                UIApplication.shared.endBackgroundTask(backgroundRecordingID)
                            }
                        }
                        
                        self.delegate?.cameraControllerDidFailRecording?(self, error: nil)
                    } else if assetWriter.status == .completed {
                        DispatchQueue.main.async {
                            if let backgroundRecordingID = self.backgroundRecordingID {
                                UIApplication.shared.endBackgroundTask(backgroundRecordingID)
                            }
                        }
                        
                        self.delegate?.cameraControllerDidFinishRecording?(self, fileURL: fileURL)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func startTimeUpdateTimer() {
        DispatchQueue.main.async {
            if let timeUpdateTimer = self.timeUpdateTimer {
                timeUpdateTimer.invalidate()
            }
            
            self.timeUpdateTimer = Timer.after(0.25, repeats: true, { () -> () in
                if let currentVideoTime = self.currentVideoTime, let videoWritingStartTime = self.videoWritingStartTime {
                    let diff = CMTimeSubtract(currentVideoTime, videoWritingStartTime)
                    let seconds = Int(CMTimeGetSeconds(diff))
                    
                    self.delegate?.cameraController?(self, recordedSeconds: seconds)
                    
                    if let maximumVideoLength = self.maximumVideoLength, seconds >= maximumVideoLength {
                        self.stopVideoRecording()
                    }
                }
            })
        }
    }
    
    func stopTimeUpdateTimer() {
        DispatchQueue.main.async {
            self.timeUpdateTimer?.invalidate()
            self.timeUpdateTimer = nil
        }
    }
    
    func addSnapshotViewsToVideoPreviewView(_ videoPreviewView: UIView) -> (snapshotWithBlur: UIView, snapshotWithoutBlur: UIView) {
        // Hiding live preview
        videoPreviewView.isHidden = true
        
        // Adding a simple snapshot and immediately showing it
        let snapshot = videoPreviewView.snapshotView(afterScreenUpdates: true)!
        snapshot.transform = videoPreviewView.transform
        snapshot.frame = previewView.frame
        previewView.superview?.addSubview(snapshot)
        
        // Creating a snapshot with a UIBlurEffect added
        let snapshotWithBlur = videoPreviewView.snapshotView(afterScreenUpdates: true)!
        snapshotWithBlur.transform = videoPreviewView.transform
        snapshotWithBlur.frame = previewView.frame
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.frame = snapshotWithBlur.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        snapshotWithBlur.addSubview(visualEffectView)
        
        return (snapshotWithBlur: snapshotWithBlur, snapshotWithoutBlur: snapshot)
    }
    
    class func deviceWithMediaType(_ mediaType: String, preferringPosition position: AVCaptureDevice.Position?) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType(rawValue: mediaType)) 
        var captureDevice = devices.first
        
        if let position = position {
            for device in devices {
                if device.position == position {
                    captureDevice = device
                    break
                }
            }
        }
        
        return captureDevice
    }
    
}

extension IMGLYCameraController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        let mediaType = CMFormatDescriptionGetMediaType(formatDescription)
        
        if mediaType == CMMediaType(kCMMediaType_Audio) {
            self.currentAudioSampleBufferFormatDescription = formatDescription
            if let assetWriterAudioInput = self.assetWriterAudioInput, assetWriterAudioInput.isReadyForMoreMediaData {
                let success = assetWriterAudioInput.append(sampleBuffer)
                if !success {
                    self.abortWriting()
                }
            }
            
            return
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        
        let sourceImage: CIImage
        if #available(iOS 9.0, *) {
            sourceImage = CIImage(cvImageBuffer: imageBuffer)
        } else {
            sourceImage = CIImage(cvPixelBuffer: imageBuffer as CVPixelBuffer)
        }
        
        let filteredImage: CIImage?
        
        if effectFilter is IMGLYNoneFilter {
            filteredImage = sourceImage
        } else {
            filteredImage = IMGLYPhotoProcessor.processWithCIImage(sourceImage, filters: [effectFilter])
        }
        
        let sourceExtent = sourceImage.extent
        
        if let videoPreviewView = videoPreviewView {
            let targetRect = CGRect(x: 0, y: 0, width: videoPreviewView.drawableWidth, height: videoPreviewView.drawableHeight)
            
            videoPreviewFrame = sourceExtent
            videoPreviewFrame.fittedIntoTargetRect(targetRect, withContentMode: previewContentMode)
            updateSquareIndicatorView(self.videoPreviewFrame)
            if glContext != EAGLContext.current() {
                EAGLContext.setCurrent(glContext)
            }
            
            videoPreviewView.bindDrawable()
            
            glClearColor(0, 0, 0, 1.0)
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            
            currentVideoTime = timestamp
            
            if let assetWriter = assetWriter {
                if !videoWritingStarted {
                    videoWritingStarted = true
                    
                    let success = assetWriter.startWriting()
                    if !success {
                        abortWriting()
                        return
                    }
                    
                    assetWriter.startSession(atSourceTime: timestamp)
                    videoWritingStartTime = timestamp
                }
                
                if let assetWriterInputPixelBufferAdaptor = assetWriterInputPixelBufferAdaptor, let pixelBufferPool = assetWriterInputPixelBufferAdaptor.pixelBufferPool {
                    var renderedOutputPixelBuffer: CVPixelBuffer?
                    let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &renderedOutputPixelBuffer)
                    if status != 0 {
                        abortWriting()
                        return
                    }
                    
                    if let filteredImage = filteredImage, let renderedOutputPixelBuffer = renderedOutputPixelBuffer {
                        ciContext?.render(filteredImage, to: renderedOutputPixelBuffer)
                        let drawImage = CIImage(cvPixelBuffer: renderedOutputPixelBuffer)
                        ciContext?.draw(drawImage, in: videoPreviewFrame, from: sourceExtent)
                        
                        if let assetWriterVideoInput = assetWriterVideoInput, assetWriterVideoInput.isReadyForMoreMediaData {
                            assetWriterInputPixelBufferAdaptor.append(renderedOutputPixelBuffer, withPresentationTime: timestamp)
                        }
                    }
                }
            } else {
                if let filteredImage = filteredImage {
                    ciContext?.draw(filteredImage, in: videoPreviewFrame, from: sourceExtent)
                }
            }
            
            videoPreviewView.display()
        }
    }
}

extension CGRect {
    mutating func fittedIntoTargetRect(_ targetRect: CGRect, withContentMode contentMode: UIView.ContentMode) {
        if !(contentMode == .scaleAspectFit || contentMode == .scaleAspectFill) {
            // Not implemented
            return
        }
        
        var scale = targetRect.width / self.width
        
        if contentMode == .scaleAspectFit {
            if self.height * scale > targetRect.height {
                scale = targetRect.height / self.height
            }
        } else if contentMode == .scaleAspectFill {
            if self.height * scale < targetRect.height {
                scale = targetRect.height / self.height
            }
        }
        
        let scaledWidth = self.width * scale
        let scaledHeight = self.height * scale
        let scaledX = targetRect.width / 2 - scaledWidth / 2
        let scaledY = targetRect.height / 2 - scaledHeight / 2
        
        self.origin.x = scaledX
        self.origin.y = scaledY
        self.size.width = scaledWidth
        self.size.height = scaledHeight
    }
}

// MARK: - Helper Functions

private func GetTransformForDeviceOrientation(_ orientation: AVCaptureVideoOrientation, mirrored: Bool = false) -> CGAffineTransform {
    let result: CGAffineTransform
    
    switch orientation {
    case .portrait:
        result = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
    case .portraitUpsideDown:
        result = CGAffineTransform(rotationAngle: 3 * CGFloat.pi / 2)
    case .landscapeRight:
        result = mirrored ? CGAffineTransform(rotationAngle: CGFloat.pi) : CGAffineTransform.identity
    case .landscapeLeft:
        result = mirrored ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat.pi)
    default:
        result = .identity
    }
    
    return result
}
