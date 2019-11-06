//
//  IMGLYCameraViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 10/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

let InitialFilterIntensity = Float(0.75)
private let ShowFilterIntensitySliderInterval = TimeInterval(2)
private let FilterSelectionViewHeight = 100
private let BottomControlSize = CGSize(width: 47, height: 47)
public typealias IMGLYCameraCompletionBlock = (UIImage?, URL?) -> (Void)

open class IMGLYCameraViewController: UIViewController {
    
    // MARK: - Initializers
    
    public convenience init() {
        self.init(recordingModes: [.photo, .video])
    }
    
    /// This initializer should only be used in Objective-C. It expects an NSArray of NSNumbers that wrap
    /// the integer value of IMGLYRecordingMode.
    public convenience init(recordingModes: [NSNumber]) {
        let modes = recordingModes.map { IMGLYRecordingMode(rawValue: $0.intValue) }.filter { $0 != nil }.map { $0! }
        self.init(recordingModes: modes)
    }
    
    /**
    Initializes a camera view controller.
    
    :param: recordingModes An array of recording modes that you want to support.
    
    :returns: An initialized IMGLYCameraViewController.
    
    :discussion: If you use the standard `init` method or `initWithCoder` to initialize a `IMGLYCameraViewController` object, a camera view controller with all supported recording modes is created.
    */
    public init(recordingModes: [IMGLYRecordingMode]) {
        assert(recordingModes.count > 0, "You need to set at least one recording mode.")
        self.recordingModes = recordingModes
        self.currentRecordingMode = recordingModes.first!
        self.squareMode = false
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        recordingModes = [.photo, .video]
        currentRecordingMode = recordingModes.first!
        self.squareMode = false
        super.init(coder: aDecoder)
    }
    
    // MARK: - Properties
    
    open fileprivate(set) lazy var backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open fileprivate(set) lazy var topControlsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
        }()
    
    open fileprivate(set) lazy var cameraPreviewContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
        }()
    
    open fileprivate(set) lazy var bottomControlsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
        }()
    
    open fileprivate(set) lazy var flashButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "flash_auto", in: bundle, compatibleWith: nil), for: [])
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(IMGLYCameraViewController.changeFlash(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
        }()
    
    open fileprivate(set) lazy var switchCameraButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "cam_switch", in: bundle, compatibleWith: nil), for: [])
        button.contentHorizontalAlignment = .right
        button.addTarget(self, action: #selector(IMGLYCameraViewController.switchCamera(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
        }()
    
    open fileprivate(set) lazy var cameraRollButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "nonePreview", in: bundle, compatibleWith: nil), for: [])
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(IMGLYCameraViewController.showCameraRoll(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var actionButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open fileprivate(set) lazy var recordingTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0
        label.textColor = UIColor.white
        label.text = "00:00"
        return label
    }()
    
    open fileprivate(set) var actionButton: UIControl?
    
    open fileprivate(set) lazy var filterSelectionButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "show_filter", in: bundle, compatibleWith: nil), for: [])
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(IMGLYCameraViewController.toggleFilters(_:)), for: .touchUpInside)
        button.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        return button
        }()
    
    open fileprivate(set) lazy var filterIntensitySlider: UISlider = {
        let bundle = Bundle(for: type(of: self))
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.75
        slider.alpha = 0
        slider.addTarget(self, action: #selector(IMGLYCameraViewController.changeIntensity(_:)), for: .valueChanged)
        
        slider.minimumTrackTintColor = UIColor.white
        slider.maximumTrackTintColor = UIColor.white
        slider.thumbTintColor = UIColor(red:1, green:0.8, blue:0, alpha:1)
        let sliderThumbImage = UIImage(named: "slider_thumb_image", in: bundle, compatibleWith: nil)
        slider.setThumbImage(sliderThumbImage, for: [])
        slider.setThumbImage(sliderThumbImage, for: .highlighted)
        
        return slider
    }()
    
    open fileprivate(set) lazy var swipeRightGestureRecognizer: UISwipeGestureRecognizer = {
        let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(IMGLYCameraViewController.toggleMode(_:)))
        return recognizer
    }()
    
    open fileprivate(set) lazy var swipeLeftGestureRecognizer: UISwipeGestureRecognizer = {
        let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(IMGLYCameraViewController.toggleMode(_:)))
        recognizer.direction = .left
        return recognizer
    }()
    
    public let recordingModes: [IMGLYRecordingMode]
    fileprivate var recordingModeSelectionButtons = [UIButton]()
    
    open fileprivate(set) var currentRecordingMode: IMGLYRecordingMode {
        didSet {
            if currentRecordingMode == oldValue {
                return
            }
            
            self.cameraController?.switchToRecordingMode(self.currentRecordingMode)
        }
    }

    open var squareMode: Bool {
        didSet {
            self.cameraController?.squareMode = squareMode
        }
    }
    
    fileprivate var hideSliderTimer: Timer?
    
    fileprivate var filterSelectionViewConstraint: NSLayoutConstraint?
    public let filterSelectionController = IMGLYFilterSelectionController()
    
    open fileprivate(set) var cameraController: IMGLYCameraController?
    
    /// The maximum length of a video. If set to 0 the length is unlimited.
    open var maximumVideoLength: Int = 0 {
        didSet {
            if maximumVideoLength == 0 {
                cameraController?.maximumVideoLength = nil
            } else {
                cameraController?.maximumVideoLength = maximumVideoLength
            }
            
            updateRecordingTimeLabel(maximumVideoLength)
        }
    }
    
    fileprivate var buttonsEnabled = true {
        didSet {
            flashButton.isEnabled = buttonsEnabled
            switchCameraButton.isEnabled = buttonsEnabled
            cameraRollButton.isEnabled = buttonsEnabled
            actionButtonContainer.isUserInteractionEnabled = buttonsEnabled
            
            for recordingModeSelectionButton in recordingModeSelectionButtons {
                recordingModeSelectionButton.isEnabled = buttonsEnabled
            }

            swipeRightGestureRecognizer.isEnabled = buttonsEnabled
            swipeLeftGestureRecognizer.isEnabled = buttonsEnabled
            filterSelectionController.view.isUserInteractionEnabled = buttonsEnabled
            filterSelectionButton.isEnabled = buttonsEnabled
        }
    }
    
    open var completionBlock: IMGLYCameraCompletionBlock?
    
    fileprivate var centerModeButtonConstraint: NSLayoutConstraint?
    fileprivate var cameraPreviewContainerTopConstraint: NSLayoutConstraint?
    fileprivate var cameraPreviewContainerBottomConstraint: NSLayoutConstraint?
    
    // MARK: - UIViewController

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        
        configureRecordingModeSwitching()
        configureViewHierarchy()
        configureViewConstraints()
        configureFilterSelectionController()
        configureCameraController()
        cameraController?.squareMode = squareMode
        cameraController?.switchToRecordingMode(currentRecordingMode, animated: false)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint, filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.beginAppearanceTransition(true, animated: animated)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint, filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.endAppearanceTransition()
        }
        
        setLastImageFromRollAsPreview()
        cameraController?.startCamera()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController?.stopCamera()
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint, filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.beginAppearanceTransition(false, animated: animated)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint, filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.endAppearanceTransition()
        }
    }
    
    open override var shouldAutomaticallyForwardAppearanceMethods : Bool {
        return false
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    open override var prefersStatusBarHidden : Bool {
        return true
    }
    
    open override var shouldAutorotate : Bool {
        return false
    }
    
    open override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .portrait
    }

    // MARK: - Configuration
    
    fileprivate func configureRecordingModeSwitching() {
        if recordingModes.count > 1 {
            view.addGestureRecognizer(swipeLeftGestureRecognizer)
            view.addGestureRecognizer(swipeRightGestureRecognizer)
            
            recordingModeSelectionButtons = recordingModes.map { $0.selectionButton }
            
            for recordingModeSelectionButton in recordingModeSelectionButtons {
                recordingModeSelectionButton.addTarget(self, action: #selector(IMGLYCameraViewController.toggleMode(_:)), for: .touchUpInside)
            }
        }
    }
    
    fileprivate func configureViewHierarchy() {
        view.addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(cameraPreviewContainer)
        view.addSubview(topControlsView)
        view.addSubview(bottomControlsView)
        
        addChild(filterSelectionController)
        filterSelectionController.didMove(toParent: self)
        view.addSubview(filterSelectionController.view)
        
        topControlsView.addSubview(flashButton)
        topControlsView.addSubview(switchCameraButton)
        
        bottomControlsView.addSubview(cameraRollButton)
        bottomControlsView.addSubview(actionButtonContainer)
        bottomControlsView.addSubview(filterSelectionButton)
        
        for recordingModeSelectionButton in recordingModeSelectionButtons {
            bottomControlsView.addSubview(recordingModeSelectionButton)
        }
        
        cameraPreviewContainer.addSubview(filterIntensitySlider)
    }
    
    fileprivate func configureViewConstraints() {
        let views: [String : AnyObject] = [
            "backgroundContainerView" : backgroundContainerView,
            "topLayoutGuide" : topLayoutGuide,
            "topControlsView" : topControlsView,
            "cameraPreviewContainer" : cameraPreviewContainer,
            "bottomControlsView" : bottomControlsView,
            "filterSelectionView" : filterSelectionController.view,
            "flashButton" : flashButton,
            "switchCameraButton" : switchCameraButton,
            "cameraRollButton" : cameraRollButton,
            "actionButtonContainer" : actionButtonContainer,
            "filterSelectionButton" : filterSelectionButton,
            "filterIntensitySlider" : filterIntensitySlider
        ]
        
        let metrics: [String : AnyObject] = [
            "topControlsViewHeight" : 44 as AnyObject,
            "filterSelectionViewHeight" : FilterSelectionViewHeight as AnyObject,
            "topControlMargin" : 20 as AnyObject,
            "topControlMinWidth" : 44 as AnyObject,
            "filterIntensitySliderLeftRightMargin" : 10 as AnyObject
        ]
        
        configureSuperviewConstraintsWithMetrics(metrics, views: views)
        configureTopControlsConstraintsWithMetrics(metrics, views: views)
        configureBottomControlsConstraintsWithMetrics(metrics, views: views)
    }
    
    fileprivate func configureSuperviewConstraintsWithMetrics(_ metrics: [String : AnyObject], views: [String : AnyObject]) {
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[backgroundContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundContainerView]|", options: [], metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[topControlsView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[cameraPreviewContainer]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[bottomControlsView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[filterSelectionView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(==filterIntensitySliderLeftRightMargin)-[filterIntensitySlider]-(==filterIntensitySliderLeftRightMargin)-|", options: [], metrics: metrics, views: views))

        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topLayoutGuide][topControlsView(==topControlsViewHeight)]", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[bottomControlsView][filterSelectionView(==filterSelectionViewHeight)]", options: [], metrics: metrics, views: views))
        view.addConstraint(NSLayoutConstraint(item: filterIntensitySlider, attribute: .bottom, relatedBy: .equal, toItem: bottomControlsView, attribute: .top, multiplier: 1, constant: -20))
        
        cameraPreviewContainerTopConstraint = NSLayoutConstraint(item: cameraPreviewContainer, attribute: .top, relatedBy: .equal, toItem: topControlsView, attribute: .bottom, multiplier: 1, constant: 0)
        cameraPreviewContainerBottomConstraint = NSLayoutConstraint(item: cameraPreviewContainer, attribute: .bottom, relatedBy: .equal, toItem: bottomControlsView, attribute: .top, multiplier: 1, constant: 0)
        view.addConstraints([cameraPreviewContainerTopConstraint!, cameraPreviewContainerBottomConstraint!])
        
        filterSelectionViewConstraint = NSLayoutConstraint(item: filterSelectionController.view!, attribute: .top, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(filterSelectionViewConstraint!)
    }
    
    fileprivate func configureTopControlsConstraintsWithMetrics(_ metrics: [String : AnyObject], views: [String : AnyObject]) {
        topControlsView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(==topControlMargin)-[flashButton(>=topControlMinWidth)]-(>=topControlMargin)-[switchCameraButton(>=topControlMinWidth)]-(==topControlMargin)-|", options: [], metrics: metrics, views: views))
        topControlsView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[flashButton]|", options: [], metrics: nil, views: views))
        topControlsView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[switchCameraButton]|", options: [], metrics: nil, views: views))
    }
    
    fileprivate func configureBottomControlsConstraintsWithMetrics(_ metrics: [String : AnyObject], views: [String : AnyObject]) {
        if recordingModeSelectionButtons.count > 0 {
            // Mode Buttons
            for i in 0 ..< recordingModeSelectionButtons.count - 1 {
                let leftButton = recordingModeSelectionButtons[i]
                let rightButton = recordingModeSelectionButtons[i + 1]
                
                bottomControlsView.addConstraint(NSLayoutConstraint(item: leftButton, attribute: .right, relatedBy: .equal, toItem: rightButton, attribute: .left, multiplier: 1, constant: -20))
                bottomControlsView.addConstraint(NSLayoutConstraint(item: leftButton, attribute: .lastBaseline, relatedBy: .equal, toItem: rightButton, attribute: .lastBaseline, multiplier: 1, constant: 0))
            }
            
            centerModeButtonConstraint = NSLayoutConstraint(item: recordingModeSelectionButtons[0], attribute: .centerX, relatedBy: .equal, toItem: actionButtonContainer, attribute: .centerX, multiplier: 1, constant: 0)
            bottomControlsView.addConstraint(centerModeButtonConstraint!)
            bottomControlsView.addConstraint(NSLayoutConstraint(item: recordingModeSelectionButtons[0], attribute: .bottom, relatedBy: .equal, toItem: actionButtonContainer, attribute: .top, multiplier: 1, constant: -5))
            bottomControlsView.addConstraint(NSLayoutConstraint(item: bottomControlsView, attribute: .top, relatedBy: .equal, toItem: recordingModeSelectionButtons[0], attribute: .top, multiplier: 1, constant: -5))
        } else {
            bottomControlsView.addConstraint(NSLayoutConstraint(item: bottomControlsView, attribute: .top, relatedBy: .equal, toItem: actionButtonContainer, attribute: .top, multiplier: 1, constant: -5))
        }
        
        // CameraRollButton
        cameraRollButton.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: BottomControlSize.width))
        cameraRollButton.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: BottomControlSize.height))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .centerY, relatedBy: .equal, toItem: actionButtonContainer, attribute: .centerY, multiplier: 1, constant: 0))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .left, relatedBy: .equal, toItem: bottomControlsView, attribute: .left, multiplier: 1, constant: 20))
        
        // ActionButtonContainer
        actionButtonContainer.addConstraint(NSLayoutConstraint(item: actionButtonContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70))
        actionButtonContainer.addConstraint(NSLayoutConstraint(item: actionButtonContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: actionButtonContainer, attribute: .centerX, relatedBy: .equal, toItem: bottomControlsView, attribute: .centerX, multiplier: 1, constant: 0))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: bottomControlsView, attribute: .bottom, relatedBy: .equal, toItem: actionButtonContainer, attribute: .bottom, multiplier: 1, constant: 10))
        
        // FilterSelectionButton
        filterSelectionButton.addConstraint(NSLayoutConstraint(item: filterSelectionButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: BottomControlSize.width))
        filterSelectionButton.addConstraint(NSLayoutConstraint(item: filterSelectionButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: BottomControlSize.height))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: filterSelectionButton, attribute: .centerY, relatedBy: .equal, toItem: actionButtonContainer, attribute: .centerY, multiplier: 1, constant: 0))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: bottomControlsView, attribute: .right, relatedBy: .equal, toItem: filterSelectionButton, attribute: .right, multiplier: 1, constant: 20))
    }
    
    fileprivate func configureCameraController() {
        // Needed so that the framebuffer can bind to OpenGL ES
        view.layoutIfNeeded()
        
        cameraController = IMGLYCameraController(previewView: cameraPreviewContainer)
        cameraController!.delegate = self
        cameraController!.setupWithInitialRecordingMode(currentRecordingMode)
        if maximumVideoLength > 0 {
            cameraController!.maximumVideoLength = maximumVideoLength
        }
    }
    
    fileprivate func configureFilterSelectionController() {
        filterSelectionController.selectedBlock = { [weak self] filterType in
            if let cameraController = self?.cameraController, cameraController.effectFilter.filterType != filterType {
                cameraController.effectFilter = IMGLYInstanceFactory.effectFilterWithType(filterType)
                cameraController.effectFilter.inputIntensity = NSNumber(value: InitialFilterIntensity)
                self?.filterIntensitySlider.value = InitialFilterIntensity
            }
            
            if filterType == .none {
                self?.hideSliderTimer?.invalidate()
                if let filterIntensitySlider = self?.filterIntensitySlider, filterIntensitySlider.alpha > 0 {
                    UIView.animate(withDuration: 0.25, animations: {
                        filterIntensitySlider.alpha = 0
                    }) 
                }
            } else {
                if let filterIntensitySlider = self?.filterIntensitySlider, filterIntensitySlider.alpha < 1 {
                    UIView.animate(withDuration: 0.25, animations: {
                        filterIntensitySlider.alpha = 1
                    }) 
                }
                
                self?.resetHideSliderTimer()
            }
        }
        
        filterSelectionController.activeFilterType = { [weak self] in
            if let cameraController = self?.cameraController {
                return cameraController.effectFilter.filterType
            } else {
                return .none
            }
        }
    }
    
    // MARK: - Helpers
    
    fileprivate func updateRecordingTimeLabel(_ seconds: Int) {
        self.recordingTimeLabel.text = NSString(format: "%02d:%02d", seconds / 60, seconds % 60) as String
    }
    
    fileprivate func addRecordingTimeLabel() {
        updateRecordingTimeLabel(maximumVideoLength)
        topControlsView.addSubview(recordingTimeLabel)
        
        topControlsView.addConstraint(NSLayoutConstraint(item: recordingTimeLabel, attribute: .centerX, relatedBy: .equal, toItem: topControlsView, attribute: .centerX, multiplier: 1, constant: 0))
        topControlsView.addConstraint(NSLayoutConstraint(item: recordingTimeLabel, attribute: .centerY, relatedBy: .equal, toItem: topControlsView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    fileprivate func updateConstraintsForRecordingMode(_ recordingMode: IMGLYRecordingMode) {
        if let cameraPreviewContainerTopConstraint = cameraPreviewContainerTopConstraint {
            view.removeConstraint(cameraPreviewContainerTopConstraint)
        }
        
        if let cameraPreviewContainerBottomConstraint = cameraPreviewContainerBottomConstraint {
            view.removeConstraint(cameraPreviewContainerBottomConstraint)
        }
        
        
        switch recordingMode {
        case .photo:
            cameraPreviewContainerTopConstraint = NSLayoutConstraint(item: cameraPreviewContainer, attribute: .top, relatedBy: .equal, toItem: topControlsView, attribute: .bottom, multiplier: 1, constant: 0)
            cameraPreviewContainerBottomConstraint = NSLayoutConstraint(item: cameraPreviewContainer, attribute: .bottom, relatedBy: .equal, toItem: bottomControlsView, attribute: .top, multiplier: 1, constant: 0)
        case .video:
            cameraPreviewContainerTopConstraint = NSLayoutConstraint(item: cameraPreviewContainer, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
            cameraPreviewContainerBottomConstraint = NSLayoutConstraint(item: cameraPreviewContainer, attribute: .bottom, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .top, multiplier: 1, constant: 0)
        }
        
        view.addConstraints([cameraPreviewContainerTopConstraint!, cameraPreviewContainerBottomConstraint!])
    }
    
    fileprivate func updateViewsForRecordingMode(_ recordingMode: IMGLYRecordingMode) {
        let color: UIColor
        
        switch recordingMode {
        case .photo:
            color = UIColor.black
        case .video:
            color = UIColor.black.withAlphaComponent(0.3)
        }
        
        topControlsView.backgroundColor = color
        bottomControlsView.backgroundColor = color
        filterSelectionController.collectionView?.backgroundColor = color
    }
    
    fileprivate func addActionButtonToContainer(_ actionButton: UIControl) {
        actionButtonContainer.addSubview(actionButton)
        actionButtonContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[actionButton]|", options: [], metrics: nil, views: [ "actionButton" : actionButton ]))
        actionButtonContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[actionButton]|", options: [], metrics: nil, views: [ "actionButton" : actionButton ]))
    }
    
    fileprivate func updateFlashButton() {
        if let cameraController = cameraController {
            let bundle = Bundle(for: type(of: self))

            if currentRecordingMode == .photo {
                flashButton.isHidden = !cameraController.flashAvailable
                
                switch(cameraController.flashMode) {
                case .auto:
                    self.flashButton.setImage(UIImage(named: "flash_auto", in: bundle, compatibleWith: nil), for: [])
                case .on:
                    self.flashButton.setImage(UIImage(named: "flash_on", in: bundle, compatibleWith: nil), for: [])
                case .off:
                    self.flashButton.setImage(UIImage(named: "flash_off", in: bundle, compatibleWith: nil), for: [])
                default:
                    break
                }
            } else if currentRecordingMode == .video {
                flashButton.isHidden = !cameraController.torchAvailable
                
                switch(cameraController.torchMode) {
                case .auto:
                    self.flashButton.setImage(UIImage(named: "flash_auto", in: bundle, compatibleWith: nil), for: [])
                case .on:
                    self.flashButton.setImage(UIImage(named: "flash_on", in: bundle, compatibleWith: nil), for: [])
                case .off:
                    self.flashButton.setImage(UIImage(named: "flash_off", in: bundle, compatibleWith: nil), for: [])
                default:
                    break
                }
            }
        } else {
            flashButton.isHidden = true
        }
    }
    
    fileprivate func resetHideSliderTimer() {
        hideSliderTimer?.invalidate()
        hideSliderTimer = Timer.scheduledTimer(timeInterval: ShowFilterIntensitySliderInterval, target: self, selector: #selector(IMGLYCameraViewController.hideFilterIntensitySlider(_:)), userInfo: nil, repeats: false)
    }
    
    fileprivate func showEditorNavigationControllerWithImage(_ image: UIImage) {
        let editorViewController = IMGLYMainEditorViewController()
        editorViewController.highResolutionImage = image
        if let cameraController = cameraController {
            editorViewController.initialFilterType = cameraController.effectFilter.filterType
            editorViewController.initialFilterIntensity = cameraController.effectFilter.inputIntensity
        }
        editorViewController.completionBlock = editorCompletionBlock
        
        let navigationController = IMGLYNavigationController(rootViewController: editorViewController)
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor : UIColor.white ]
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func saveMovieWithMovieURLToAssets(_ movieURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieURL)
            }) { success, error in
                if let error = error {
                    DispatchQueue.main.async {
                        let bundle = Bundle(for: type(of: self))
                        
                        let alertController = UIAlertController(title: NSLocalizedString("camera-view-controller.error-saving-video.title", tableName: nil, bundle: bundle, value: "", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: NSLocalizedString("camera-view-controller.error-saving-video.cancel", tableName: nil, bundle: bundle, value: "", comment: ""), style: .cancel, handler: nil)
                        
                        alertController.addAction(cancelAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
                
                do {
                    try FileManager.default.removeItem(at: movieURL)
                } catch _ {
                }
        }
    }
    
    open func setLastImageFromRollAsPreview() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if fetchResult.lastObject != nil {
            let lastAsset: PHAsset = fetchResult.lastObject!
            PHImageManager.default().requestImage(for: lastAsset, targetSize: CGSize(width: BottomControlSize.width * 2, height: BottomControlSize.height * 2), contentMode: PHImageContentMode.aspectFill, options: PHImageRequestOptions()) { (result, info) -> Void in
                self.cameraRollButton.setImage(result, for: [])
            }
        }
    }
    
    // MARK: - Targets
    
    @objc fileprivate func toggleMode(_ sender: AnyObject?) {
        if let gestureRecognizer = sender as? UISwipeGestureRecognizer {
            if gestureRecognizer.direction == .left {
                let currentIndex = recordingModes.firstIndex(of: currentRecordingMode)
                
                if let currentIndex = currentIndex, currentIndex < recordingModes.count - 1 {
                    currentRecordingMode = recordingModes[currentIndex + 1]
                    return
                }
            } else if gestureRecognizer.direction == .right {
                let currentIndex = recordingModes.firstIndex(of: currentRecordingMode)
                
                if let currentIndex = currentIndex, currentIndex > 0 {
                    currentRecordingMode = recordingModes[currentIndex - 1]
                    return
                }
            }
        }
        
        if let button = sender as? UIButton {
            let buttonIndex = recordingModeSelectionButtons.firstIndex(of: button)
            
            if let buttonIndex = buttonIndex {
                currentRecordingMode = recordingModes[buttonIndex]
                return
            }
        }
    }
    
    @objc fileprivate func hideFilterIntensitySlider(_ timer: Timer?) {
        UIView.animate(withDuration: 0.25, animations: {
            self.filterIntensitySlider.alpha = 0
            self.hideSliderTimer = nil
        }) 
    }
    
    @objc open func changeFlash(_ sender: UIButton?) {
        switch(currentRecordingMode) {
        case .photo:
            cameraController?.selectNextFlashMode()
        case .video:
            cameraController?.selectNextTorchMode()
        }
    }
    
    @objc open func switchCamera(_ sender: UIButton?) {
        cameraController?.toggleCameraPosition()
    }
    
    @objc open func showCameraRoll(_ sender: UIButton?) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.mediaTypes = [String(kUTTypeImage)]
        imagePicker.allowsEditing = false
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc open func takePhoto(_ sender: UIButton?) {
        cameraController?.takePhoto { image, error in
            if error == nil {
                DispatchQueue.main.async {
                    if let completionBlock = self.completionBlock {
                        completionBlock(image, nil)
                    } else {
                        if let image = image {
                            self.showEditorNavigationControllerWithImage(image)
                        }
                    }
                }
            }
        }
    }
    
    @objc open func recordVideo(_ sender: IMGLYVideoRecordButton?) {
        if let recordVideoButton = sender {
            if recordVideoButton.recording {
                cameraController?.startVideoRecording()
            } else {
                cameraController?.stopVideoRecording()
            }
            
            if let filterSelectionViewConstraint = filterSelectionViewConstraint, filterSelectionViewConstraint.constant != 0 {
                toggleFilters(filterSelectionButton)
            }
        }
    }
    
    @objc open func toggleFilters(_ sender: UIButton?) {
        if let filterSelectionViewConstraint = self.filterSelectionViewConstraint {
            let animationDuration = TimeInterval(0.6)
            let dampingFactor = CGFloat(0.6)
            
            if filterSelectionViewConstraint.constant == 0 {
                // Expand
                filterSelectionController.beginAppearanceTransition(true, animated: true)
                filterSelectionViewConstraint.constant = -1 * CGFloat(FilterSelectionViewHeight)
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: dampingFactor, initialSpringVelocity: 0, options: [], animations: {
                    sender?.transform = CGAffineTransform.identity
                    self.view.layoutIfNeeded()
                    }, completion: { finished in
                        self.filterSelectionController.endAppearanceTransition()
                })
            } else {
                // Close
                filterSelectionController.beginAppearanceTransition(false, animated: true)
                filterSelectionViewConstraint.constant = 0
                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: dampingFactor, initialSpringVelocity: 0, options: [], animations: {
                    sender?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                    self.view.layoutIfNeeded()
                    }, completion: { finished in
                        self.filterSelectionController.endAppearanceTransition()
                })
            }
        }
    }
    
    @objc fileprivate func changeIntensity(_ sender: UISlider?) {
        if let slider = sender {
            resetHideSliderTimer()
            cameraController?.effectFilter.inputIntensity = NSNumber(value: slider.value)
        }
    }
    
    // MARK: - Completion
    
    fileprivate func editorCompletionBlock(_ result: IMGLYEditorResult, image: UIImage?) {
        if let image = image, result == .done {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(IMGLYCameraViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func image(_ image: UIImage, didFinishSavingWithError: NSError, contextInfo:UnsafeRawPointer) {
        setLastImageFromRollAsPreview()
    }

}

extension IMGLYCameraViewController: IMGLYCameraControllerDelegate {
    public func cameraControllerDidStartCamera(_ cameraController: IMGLYCameraController) {
        DispatchQueue.main.async {
            self.buttonsEnabled = true
        }
    }
    
    public func cameraControllerDidStopCamera(_ cameraController: IMGLYCameraController) {
        DispatchQueue.main.async {
            self.buttonsEnabled = false
        }
    }
    
    public func cameraControllerDidStartStillImageCapture(_ cameraController: IMGLYCameraController) {
        DispatchQueue.main.async {
            // Animate the actionButton if it is a UIButton and has a sequence of images set
            (self.actionButtonContainer.subviews.first as? UIButton)?.imageView?.startAnimating()
            self.buttonsEnabled = false
        }
    }
    
    public func cameraControllerDidFailAuthorization(_ cameraController: IMGLYCameraController) {
        DispatchQueue.main.async {
            let bundle = Bundle(for: type(of: self))

            let alertController = UIAlertController(title: NSLocalizedString("camera-view-controller.camera-no-permission.title", tableName: nil, bundle: bundle, value: "", comment: ""), message: NSLocalizedString("camera-view-controller.camera-no-permission.message", tableName: nil, bundle: bundle, value: "", comment: ""), preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: NSLocalizedString("camera-view-controller.camera-no-permission.settings", tableName: nil, bundle: bundle, value: "", comment: ""), style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("camera-view-controller.camera-no-permission.cancel", tableName: nil, bundle: bundle, value: "", comment: ""), style: .cancel, handler: nil)
            
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, didChangeToFlashMode flashMode: AVCaptureDevice.FlashMode) {
        DispatchQueue.main.async {
            self.updateFlashButton()
        }
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, didChangeToTorchMode torchMode: AVCaptureDevice.TorchMode) {
        DispatchQueue.main.async {
            self.updateFlashButton()
        }
    }
    
    public func cameraControllerDidCompleteSetup(_ cameraController: IMGLYCameraController) {
        DispatchQueue.main.async {
            self.updateFlashButton()
            self.switchCameraButton.isHidden = !cameraController.moreThanOneCameraPresent
        }
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, willSwitchToCameraPosition cameraPosition: AVCaptureDevice.Position) {
        DispatchQueue.main.async {
            self.buttonsEnabled = false
        }
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, didSwitchToCameraPosition cameraPosition: AVCaptureDevice.Position) {
        DispatchQueue.main.async {
            self.buttonsEnabled = true
            self.updateFlashButton()
        }
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, willSwitchToRecordingMode recordingMode: IMGLYRecordingMode) {
        buttonsEnabled = false
        
        if let centerModeButtonConstraint = centerModeButtonConstraint {
            bottomControlsView.removeConstraint(centerModeButtonConstraint)
        }
        
        // add new action button to container
        let actionButton = currentRecordingMode.actionButton
        actionButton.addTarget(self, action: currentRecordingMode.actionSelector, for: .touchUpInside)
        actionButton.alpha = 0
        self.addActionButtonToContainer(actionButton)
        actionButton.layoutIfNeeded()
        
        let buttonIndex = recordingModes.firstIndex(of: currentRecordingMode)!
        if recordingModeSelectionButtons.count >= buttonIndex + 1 {
            let target = recordingModeSelectionButtons[buttonIndex]
            
            // create new centerModeButtonConstraint
            self.centerModeButtonConstraint = NSLayoutConstraint(item: target, attribute: .centerX, relatedBy: .equal, toItem: actionButtonContainer, attribute: .centerX, multiplier: 1, constant: 0)
            self.bottomControlsView.addConstraint(centerModeButtonConstraint!)
        }
        
        // add recordingTimeLabel
        if recordingMode == .video {
            self.addRecordingTimeLabel()
            self.cameraController?.hideSquareMask()
        } else {
            if self.squareMode {
                self.cameraController?.showSquareMask()
            }
        }
        
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, didSwitchToRecordingMode recordingMode: IMGLYRecordingMode) {
        DispatchQueue.main.async {
            self.setLastImageFromRollAsPreview()
            self.buttonsEnabled = true
            
            if recordingMode == .photo {
                self.recordingTimeLabel.removeFromSuperview()
            }
        }
    }
    
    public func cameraControllerAnimateAlongsideFirstPhaseOfRecordingModeSwitchBlock(_ cameraController: IMGLYCameraController) -> (() -> Void) {
        return {
            let buttonIndex = self.recordingModes.firstIndex(of: self.currentRecordingMode)!
            if self.recordingModeSelectionButtons.count >= buttonIndex + 1 {
                let target = self.recordingModeSelectionButtons[buttonIndex]
                
                // mark target as selected
                target.isSelected = true
                
                // deselect all other buttons
                for recordingModeSelectionButton in self.recordingModeSelectionButtons {
                    if recordingModeSelectionButton != target {
                        recordingModeSelectionButton.isSelected = false
                    }
                }
            }
            
            // fade new action button in and old action button out
            let actionButton = self.actionButtonContainer.subviews.last as? UIControl
            
            // fetch previous action button from container
            let previousActionButton = self.actionButtonContainer.subviews.first as? UIControl
            actionButton?.alpha = 1
            
            if let previousActionButton = previousActionButton, let actionButton = actionButton, previousActionButton != actionButton {
                previousActionButton.alpha = 0
            }
            
            self.cameraRollButton.alpha = self.currentRecordingMode == .video ? 0 : 1
            
            self.bottomControlsView.layoutIfNeeded()
        }
    }
    
    public func cameraControllerFirstPhaseOfRecordingModeSwitchAnimationCompletionBlock(_ cameraController: IMGLYCameraController) -> (() -> Void) {
        return {
            if self.actionButtonContainer.subviews.count > 1 {
                // fetch previous action button from container
                let previousActionButton = self.actionButtonContainer.subviews.first as? UIControl
                
                // remove old action button
                previousActionButton?.removeFromSuperview()
            }
            
            self.updateConstraintsForRecordingMode(self.currentRecordingMode)
        }
    }
    
    public func cameraControllerAnimateAlongsideSecondPhaseOfRecordingModeSwitchBlock(_ cameraController: IMGLYCameraController) -> (() -> Void) {
        return {
            // update constraints for view hierarchy
            self.updateViewsForRecordingMode(self.currentRecordingMode)
            
            self.recordingTimeLabel.alpha = self.currentRecordingMode == .video ? 1 : 0
        }
    }
    
    public func cameraControllerDidStartRecording(_ cameraController: IMGLYCameraController) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.swipeLeftGestureRecognizer.isEnabled = false
                self.swipeRightGestureRecognizer.isEnabled = false
                
                self.switchCameraButton.alpha = 0
                self.filterSelectionButton.alpha = 0
                self.bottomControlsView.backgroundColor = UIColor.clear
                
                for recordingModeSelectionButton in self.recordingModeSelectionButtons {
                    recordingModeSelectionButton.alpha = 0
                }
            }) 
        }
    }
    
    fileprivate func updateUIForStoppedRecording() {
        UIView.animate(withDuration: 0.25, animations: {
            self.swipeLeftGestureRecognizer.isEnabled = true
            self.swipeRightGestureRecognizer.isEnabled = true
            
            self.switchCameraButton.alpha = 1
            self.filterSelectionButton.alpha = 1
            self.bottomControlsView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            
            self.updateRecordingTimeLabel(self.maximumVideoLength)
            
            for recordingModeSelectionButton in self.recordingModeSelectionButtons {
                recordingModeSelectionButton.alpha = 1
            }
            
            if let actionButton = self.actionButtonContainer.subviews.first as? IMGLYVideoRecordButton {
                actionButton.recording = false
            }
        }) 
    }
    
    public func cameraControllerDidFailRecording(_ cameraController: IMGLYCameraController, error: NSError?) {
        DispatchQueue.main.async {
            self.updateUIForStoppedRecording()
            
            let alertController = UIAlertController(title: "Error", message: "Video recording failed", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    public func cameraControllerDidFinishRecording(_ cameraController: IMGLYCameraController, fileURL: URL) {
        DispatchQueue.main.async {
            self.updateUIForStoppedRecording()
            if let completionBlock = self.completionBlock {
                completionBlock(nil, fileURL)
            } else {
                self.saveMovieWithMovieURLToAssets(fileURL)
            }
        }
    }
    
    public func cameraController(_ cameraController: IMGLYCameraController, recordedSeconds seconds: Int) {
        let displayedSeconds: Int
        
        if maximumVideoLength > 0 {
            displayedSeconds = maximumVideoLength - seconds
        } else {
            displayedSeconds = seconds
        }
        
        DispatchQueue.main.async {
            self.updateRecordingTimeLabel(displayedSeconds)
        }
    }
}

extension IMGLYCameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
        
        self.dismiss(animated: true, completion: {
            if let completionBlock = self.completionBlock {
                completionBlock(image, nil)
            } else {
                if let image = image {
                    self.showEditorNavigationControllerWithImage(image)
                }
            }
        })
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
