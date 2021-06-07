//
//  IMGLYStrickersManager.swift
//  imglyKit2
//
//  Created by Dhaker Trimech on 24/05/2021.
//

import Foundation
import AVFoundation

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
            if gifImage.count > 0 {
                let settings = IMGLYImagesToVideoUtils.videoSettings(codec: AVVideoCodecType.h264.rawValue, width: (gifImage[0].cgImage?.width)!, height: (gifImage[0].cgImage?.height)!)
                let movieMaker = IMGLYImagesToVideoUtils(videoSettings: settings)
                movieMaker.createMovieFrom(images: gifImage){ (fileURL:URL) in
                    completionHandler(fileURL)
                }
            } else {
                completionHandler(nil)
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
            if let framesArray = gifView.sticker?.animatedFrames {
                framesPos.append(ImagesPosition(imageView: gifView, images: framesArray))
            } else {
                print("framesArray is empty")
            }
        }
    })
    
    framesPos.sort { $0.images.count > $1.images.count }
    if framesPos.count > 0 {
        for (index, _) in framesPos[0].images.enumerated() {
            framesPos.forEach { (imagePos) in
                imagePos.imageView.image = imagePos.images[(index % imagePos.images.count)]
            }
            let gifImage = stickersClipView.asImage(rect: stickersClipView.frame)
            gifArray.append(gifImage)
        }
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
