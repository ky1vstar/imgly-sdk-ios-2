//
//  IMGLYStrickersManager.swift
//  imglyKit2
//
//  Created by Dhaker Trimech on 24/05/2021.
//

import Foundation

open class IMGLYStrickersManager {
   
    public static let shared = IMGLYStrickersManager()
    open var dataArray = [IMGLYSticker?]()

    open var stickersClipView =  UIView()
    open var addedGifStickers = false
   
    func generateVideo(_ image: UIImage, completionHandler: @escaping  (URL?) -> Void)  {
        let view = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: self.stickersClipView.frame.size))
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.stickersClipView.frame.size)
        view.addSubview(imageView)
        let subViews = self.stickersClipView.subviews
        for subview in subViews {
            view.addSubview(subview)
        }
       
        self.trickyGif(stickersClipView: view) { gifImage in
            let settings = ImagesToVideoUtils.videoSettings(codec: AVVideoCodecType.h264.rawValue, width: (gifImage[0].cgImage?.width)!, height: (gifImage[0].cgImage?.height)!)
            let movieMaker = ImagesToVideoUtils(videoSettings: settings)
            movieMaker.createMovieFrom(images: gifImage){ (fileURL:URL) in
                completionHandler(fileURL)
            }
        }
    }
    
    func trickyGif(stickersClipView: UIView, completionHandler: @escaping ([UIImage]) -> Void) -> Void {
        let gifArray = self.replaceGif(stickersClipView: stickersClipView)
        completionHandler(gifArray)
    }
    
    func replaceGif(stickersClipView: UIView, imageViewPos: ImagesPosition? = nil) -> [UIImage] {
        
        var framesPos = [ImagesPosition]()
        if let imageViewPos = imageViewPos {
            framesPos.append(imageViewPos)
        }
        var gifArray = [UIImage]()
        stickersClipView.subviews.forEach({ (subview) in
            
            if let gifView = subview as? IMGLYGIFImageView, gifView.isAnimatingGIF {
                let framesArray = gifView.sticker?.animatedFrames
                framesPos.append(ImagesPosition(imageView: gifView, images: framesArray!))
            }
        })
    
        framesPos.sort { $0.images.count > $1.images.count }
        for (index, _) in framesPos[0].images.enumerated() {
            framesPos.forEach { (imagePos) in
                imagePos.imageView.image = imagePos.images[(index % imagePos.images.count)]
            }
            let gifImage = stickersClipView.asImage(rect: stickersClipView.frame)
            gifArray.append(gifImage)
        }
        return gifArray
    }
}

extension UIView {
    func asImage(rect: CGRect?) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect ?? bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

struct ImagesPosition {
    let imageView: UIImageView
    let images: [UIImage]
}

import Foundation
import AVFoundation
import UIKit

typealias CXEMovieMakerCompletion = (URL) -> Void
typealias CXEMovieMakerUIImageExtractor = (AnyObject) -> UIImage?


public class ImagesToVideoUtils: NSObject {
    
    static let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    static let tempPath = paths[0] + "/exportvideo.mp4"
    static let fileURL = URL(fileURLWithPath: tempPath)
    //    static let tempPath = NSTemporaryDirectory() + "/exprotvideo.mp4"
    //    static let fileURL = URL(fileURLWithPath: tempPath)
    
    
    var assetWriter:AVAssetWriter!
    var writeInput:AVAssetWriterInput!
    var bufferAdapter:AVAssetWriterInputPixelBufferAdaptor!
    var videoSettings:[String : Any]!
    var frameTime:CMTime!
    
    var completionBlock: CXEMovieMakerCompletion?
    var movieMakerUIImageExtractor:CXEMovieMakerUIImageExtractor?
    
    
    public class func videoSettings(codec:String, width:Int, height:Int) -> [String: Any]{
        if(Int(width) % 16 != 0){
            print("warning: video settings width must be divisible by 16")
        }
        
        let videoSettings:[String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, //AVVideoCodecH264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height]
        
        return videoSettings
    }
    
    public init(videoSettings: [String: Any]) {
        super.init()
        
        
        if Foundation.FileManager.default.fileExists(atPath: ImagesToVideoUtils.tempPath) {
            guard (try? Foundation.FileManager.default.removeItem(atPath: ImagesToVideoUtils.tempPath)) != nil else {
                print("remove path failed")
                return
            }
        }
        
        self.assetWriter = try! AVAssetWriter(url: ImagesToVideoUtils.fileURL, fileType: AVFileType.mov)
        
        self.videoSettings = videoSettings
        self.writeInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        assert(self.assetWriter.canAdd(self.writeInput), "add failed")
        
        self.assetWriter.add(self.writeInput)
        let bufferAttributes:[String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
        self.bufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.writeInput, sourcePixelBufferAttributes: bufferAttributes)
        self.frameTime = CMTimeMake(value: 1, timescale: 13)
        
    }
    
    func createMovieFrom(urls: [URL], withCompletion: @escaping CXEMovieMakerCompletion){
        self.createMovieFromSource(images: urls as [AnyObject], extractor:{(inputObject:AnyObject) ->UIImage? in
            return UIImage(data: try! Data(contentsOf: inputObject as! URL))}, withCompletion: withCompletion)
    }
    
    func createMovieFrom(images: [UIImage], withCompletion: @escaping CXEMovieMakerCompletion){
        self.createMovieFromSource(images: images, extractor: {(inputObject:AnyObject) -> UIImage? in
            return inputObject as? UIImage}, withCompletion: withCompletion)
    }
    
    func createMovieFromSource(images: [AnyObject], extractor: @escaping CXEMovieMakerUIImageExtractor, withCompletion: @escaping CXEMovieMakerCompletion){
        self.completionBlock = withCompletion
        
        self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: CMTime.zero)
        
        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
        var i = 0
        let frameNumber = images.count
        
        self.writeInput.requestMediaDataWhenReady(on: mediaInputQueue){
            while(true){
                if(i >= frameNumber){
                    break
                }
                
                if (self.writeInput.isReadyForMoreMediaData){
                    var sampleBuffer:CVPixelBuffer?
                    autoreleasepool{
                        let img = extractor(images[i])
                        if img == nil{
                            i += 1
                            print("Warning: counld not extract one of the frames")
                            //continue
                        }
                        sampleBuffer = self.newPixelBufferFrom(cgImage: img!.cgImage!)
                    }
                    if (sampleBuffer != nil){
                        if(i == 0){
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: CMTime.zero)
                        }else{
                            let value = i - 1
                            let lastTime = CMTimeMake(value: Int64(value), timescale: self.frameTime.timescale)
                            let presentTime = CMTimeAdd(lastTime, self.frameTime)
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: presentTime)
                        }
                        i = i + 1
                    }
                }
            }
            self.writeInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.sync {
                    self.completionBlock!(ImagesToVideoUtils.fileURL)
                }
            }
        }
    }
    
    func newPixelBufferFrom(cgImage:CGImage) -> CVPixelBuffer?{
        let options:[String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        var pxbuffer:CVPixelBuffer?
        let frameWidth = self.videoSettings[AVVideoWidthKey] as! Int
        let frameHeight = self.videoSettings[AVVideoHeightKey] as! Int
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: frameWidth, height: frameHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }
}
