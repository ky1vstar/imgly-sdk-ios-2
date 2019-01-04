//
//  IMGLYStickerFilter.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 24/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

#if os(iOS)
import UIKit
import CoreImage
#elseif os(OSX)
import AppKit
import QuartzCore
#endif

import CoreGraphics

open class IMGLYStickerFilter: CIFilter {
    /// A CIImage object that serves as input for the filter.
    @objc open var inputImage: CIImage?
    
    /// The sticker that should be rendered.
    #if os(iOS)
    open var sticker: UIImage?
    #elseif os(OSX)
    public var sticker: NSImage?
    #endif
    
    /// The transform to apply to the sticker
    open var transform = CGAffineTransform.identity
    
    /// The relative center of the sticker within the image.
    open var center = CGPoint()
    
    /// The relative scale of the sticker within the image.
    open var scale = CGFloat(1.0)
    
    override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Returns a CIImage object that encapsulates the operations configured in the filter. (read-only)
    open override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        if sticker == nil {
            return inputImage
        }
        
        let stickerImage = createStickerImage()
        
        guard let cgImage = stickerImage.cgImage, let filter = CIFilter(name: "CISourceOverCompositing") else {
            return inputImage
        }
        
        let stickerCIImage = CIImage(cgImage: cgImage)
        filter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        filter.setValue(stickerCIImage, forKey: kCIInputImageKey)
        return filter.outputImage
    }
    
    open func absolutStickerSizeForImageSize(_ imageSize: CGSize) -> CGSize {
        let stickerRatio = sticker!.size.height / sticker!.size.width
        return CGSize(width: self.scale * imageSize.width, height: self.scale * stickerRatio * imageSize.width)
    }
    
    #if os(iOS)
    
    fileprivate func createStickerImage() -> UIImage {
        let rect = inputImage!.extent
        let imageSize = rect.size
        UIGraphicsBeginImageContext(imageSize)
        UIColor(white: 1.0, alpha: 0.0).setFill()
        UIRectFill(CGRect(origin: CGPoint(), size: imageSize))
        
        if let context = UIGraphicsGetCurrentContext() {
            drawStickerInContext(context, withImageOfSize: imageSize)
        }
    
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    #elseif os(OSX)
    
    private func createStickerImage() -> NSImage {
        let rect = inputImage!.extent
        let imageSize = rect.size
        
        let image = NSImage(size: imageSize)
        image.lockFocus()
        NSColor(white: 1, alpha: 0).setFill()
        CGRect(origin: CGPoint(), size: imageSize).fill()

        let context = NSGraphicsContext.current!.cgContext
        drawStickerInContext(context, withImageOfSize: imageSize)
        
        image.unlockFocus()
        
        return image
    }
    
    #endif
    
    fileprivate func drawStickerInContext(_ context: CGContext, withImageOfSize imageSize: CGSize) {
        context.saveGState()
        
        let center = CGPoint(x: self.center.x * imageSize.width, y: self.center.y * imageSize.height)
        let size = self.absolutStickerSizeForImageSize(imageSize)
        let imageRect = CGRect(origin: center, size: size)
        
        // Move center to origin
        context.translateBy(x: imageRect.origin.x, y: imageRect.origin.y)
        // Apply the transform
        context.concatenate(self.transform)
        // Move the origin back by half
        context.translateBy(x: imageRect.size.width * -0.5, y: imageRect.size.height * -0.5)
        
        sticker?.draw(in: CGRect(origin: CGPoint(), size: size))
        context.restoreGState()
    }
}

extension IMGLYStickerFilter {
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! IMGLYStickerFilter
        copy.inputImage = inputImage?.copy(with: zone) as? CIImage
        copy.sticker = sticker
        copy.center = center
        copy.scale = scale
        copy.transform = transform
        return copy
    }
}
