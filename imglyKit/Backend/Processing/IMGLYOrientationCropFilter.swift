//
//  IMGLYOrientationCropFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 20/02/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

#if os(iOS)
import CoreImage
#elseif os(OSX)
import AppKit
import QuartzCore
#endif

/**
Represents the angle an image should be rotated by.
*/
@objc public enum IMGLYRotationAngle: Int {
    case _0
    case _90
    case _180
    case _270
}

/**
  Performes a rotation/flip operation and then a crop.
 Note that the result of the rotate/flip operation id transfered  to a temp CGImage.
 This is needed since otherwise the resulting CIImage has no no size due the lack of inforamtion within
 the CIImage.
*/
open class IMGLYOrientationCropFilter : CIFilter {
    /// A CIImage object that serves as input for the filter.
    @objc open var inputImage:CIImage?
    open var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    open var rotationAngle = IMGLYRotationAngle._0
    
    fileprivate var flipVertical_ = false
    fileprivate var flipHorizontal_ = false
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.imgly_displayName = "OrientationCropFilter"
    }
    
    override init() {
        super.init()
        self.imgly_displayName = "OrientationCropFilter"
    }
    
    /// Returns a CIImage object that encapsulates the operations configured in the filter. (read-only)
    open override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        let radiant = realNumberForRotationAngle(rotationAngle)
        let rotationTransformation = CGAffineTransform(rotationAngle: radiant)
        let flipH: CGFloat = flipHorizontal_ ? -1 : 1
        let flipV: CGFloat = flipVertical_ ? -1 : 1
        var flipTransformation = rotationTransformation.scaledBy(x: flipH, y: flipV)
        
        guard let filter = CIFilter(name: "CIAffineTransform") else {
            return inputImage
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        
        if let orientation = inputImage.properties["Orientation"] as? NSNumber {
            // Rotate image to match image orientation before cropping
            let transform = inputImage.orientationTransform(forExifOrientation: orientation.int32Value)
            flipTransformation = flipTransformation.concatenating(transform)
        }
        
        #if os(iOS)
            let transform = NSValue(cgAffineTransform: flipTransformation)
            #elseif os(OSX)
            let transform = NSAffineTransform(CGAffineTransform: flipTransformation)
        #endif
        
        filter.setValue(transform, forKey: kCIInputTransformKey)
        var outputImage = filter.outputImage
        
        let cropFilter = IMGLYCropFilter()
        cropFilter.cropRect = cropRect
        cropFilter.setValue(outputImage, forKey: kCIInputImageKey)
        outputImage = cropFilter.outputImage
        
        if let orientation = inputImage.properties["Orientation"] as? NSNumber {
            // Rotate image back to match metadata
            let invertedTransform = inputImage.orientationTransform(forExifOrientation: orientation.int32Value).inverted()
            
            guard let filter = CIFilter(name: "CIAffineTransform") else {
                return outputImage
            }
            
            #if os(iOS)
                let transform = NSValue(cgAffineTransform: invertedTransform)
                #elseif os(OSX)
                let transform = NSAffineTransform(CGAffineTransform: invertedTransform)
            #endif
            
            filter.setValue(transform, forKey: kCIInputTransformKey)
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            outputImage = filter.outputImage
        }
        
        return outputImage
    }
    
    fileprivate func realNumberForRotationAngle(_ rotationAngle: IMGLYRotationAngle) -> CGFloat {
        switch (rotationAngle) {
        case IMGLYRotationAngle._0:
             return 0
        case IMGLYRotationAngle._90:
            return CGFloat.pi / 2
        case IMGLYRotationAngle._180:
            return CGFloat.pi
        case IMGLYRotationAngle._270:
            return CGFloat.pi / 2 + CGFloat.pi
        }
    }
    
    // MARK:- orientation modifier {
    /**
        Sets internal flags so that the filtered image will be rotated counter-clock-wise around 90 degrees.
    */
    open func rotateLeft() {
        switch (rotationAngle) {
        case IMGLYRotationAngle._0:
            rotationAngle = IMGLYRotationAngle._90
        case IMGLYRotationAngle._90:
            rotationAngle = IMGLYRotationAngle._180
        case IMGLYRotationAngle._180:
            rotationAngle = IMGLYRotationAngle._270
        case IMGLYRotationAngle._270:
            rotationAngle = IMGLYRotationAngle._0
        }
    }
        
    /**
        Sets internal flags so that the filtered image will be rotated clock-wise around 90 degrees.
    */
    open func rotateRight() {
        switch (self.rotationAngle) {
        case IMGLYRotationAngle._0:
            rotationAngle = IMGLYRotationAngle._270
        case IMGLYRotationAngle._90:
            rotationAngle = IMGLYRotationAngle._0
        case IMGLYRotationAngle._180:
            rotationAngle = IMGLYRotationAngle._90
        case IMGLYRotationAngle._270:
            rotationAngle = IMGLYRotationAngle._180
        }
    }

    /**
    Sets internal flags so that the filtered image will be rotated flipped along the horizontal axis.
    */
    open func flipHorizontal() {
        if (rotationAngle == IMGLYRotationAngle._0 || rotationAngle == IMGLYRotationAngle._180) {
            flipHorizontal_ = !flipHorizontal_
        } else {
            flipVertical_ = !flipVertical_
        }
    }
    
    /**
    Sets internal flags so that the filtered image will be rotated flipped along the vertical axis.
    */
    open func flipVertical() {
        if (rotationAngle == IMGLYRotationAngle._0 || rotationAngle == IMGLYRotationAngle._180) {
            flipVertical_ = !flipVertical_
        } else {
            flipHorizontal_ = !flipHorizontal_
        }
    }
}

extension IMGLYOrientationCropFilter {
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! IMGLYOrientationCropFilter
        copy.inputImage = inputImage?.copy(with: zone) as? CIImage
        copy.cropRect = cropRect
        copy.rotationAngle = rotationAngle
        copy.flipVertical_ = flipVertical_
        copy.flipHorizontal_ = flipHorizontal_
        return copy
    }
}
