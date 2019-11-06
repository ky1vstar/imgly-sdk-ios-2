//
//  IMGLYTextFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 05/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

#if os(iOS)
import CoreImage
import UIKit
#elseif os(OSX)
import QuartzCore
import AppKit
#endif

open class IMGLYTextFilter : CIFilter {
    /// A CIImage object that serves as input for the filter.
    @objc open var inputImage:CIImage?
    /// The text that should be rendered.
    open var text = ""
    /// The name of the used font.
    open var fontName = "Helvetica Neue"
    ///  This factor determins the font-size. Its a relative value that is multiplied with the image height
    ///  during the process.
    open var fontScaleFactor = CGFloat(1)
    /// The relative frame of the text within the image.
    open var frame = CGRect()
    /// The color of the text.
    #if os(iOS)
    open var color = UIColor.white
    #elseif os(OSX)
    public var color = NSColor.white
    #endif
    
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
        
        if text.isEmpty {
            return inputImage
        }
        
        let textImage = createTextImage()
        
        if let cgImage = textImage.cgImage, let filter = CIFilter(name: "CISourceOverCompositing") {
            let textCIImage = CIImage(cgImage: cgImage)
            filter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
            filter.setValue(textCIImage, forKey: kCIInputImageKey)
            return filter.outputImage
        } else {
            return inputImage
        }
    }
    
    #if os(iOS)
    
    fileprivate func createTextImage() -> UIImage {
        let rect = inputImage!.extent
        let imageSize = rect.size
        UIGraphicsBeginImageContext(imageSize)
        UIColor(white: 1.0, alpha: 0.0).setFill()
        UIRectFill(CGRect(origin: CGPoint(), size: imageSize))
        
        let font = UIFont(name: fontName, size: fontScaleFactor * imageSize.height)
        text.draw(in: CGRect(x: frame.origin.x * imageSize.width, y: frame.origin.y * imageSize.height, width: frame.size.width * imageSize.width, height: frame.size.height * imageSize.width), withAttributes: [NSAttributedString.Key.font: font!, NSAttributedString.Key.foregroundColor: color])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    #elseif os(OSX)
    
    private func createTextImage() -> NSImage {
        let rect = inputImage!.extent
        let imageSize = rect.size
    
        let image = NSImage(size: imageSize)
        image.lockFocus()
    
        NSColor(white: 1, alpha: 0).setFill()
        CGRect(origin: CGPoint(), size: imageSize).fill()
        let font = NSFont(name: fontName, size: fontScaleFactor * imageSize.height)
        text.draw(in: CGRect(x: frame.origin.x * imageSize.width, y: frame.origin.y * imageSize.height, width: frame.size.width * imageSize.width, height: frame.size.height * imageSize.width), withAttributes: [NSAttributedString.Key.font: font!, NSAttributedString.Key.foregroundColor: color])
    
        image.unlockFocus()
        
        return image
    }

    #endif
}

extension IMGLYTextFilter {
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! IMGLYTextFilter
        copy.inputImage = inputImage?.copy(with: zone) as? CIImage
        copy.text = (text as NSString).copy(with: zone) as! String
        copy.fontName = (fontName as NSString).copy(with: zone) as! String
        copy.fontScaleFactor = fontScaleFactor
        copy.frame = frame
        #if os(iOS)
        copy.color = color.copy(with: zone) as! UIColor
        #elseif os(OSX)
        copy.color = color.copy(with: zone) as! NSColor
        #endif
        
        return copy
    }
}
