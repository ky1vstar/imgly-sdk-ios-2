//
//  IMGLYContrastBrightnessSaturationFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 04/02/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

#if os(iOS)
import CoreImage
#elseif os(OSX)
import QuartzCore
#endif

open class IMGLYContrastBrightnessSaturationFilter : CIFilter {
    /// A CIImage object that serves as input for the filter.
    @objc open var inputImage:CIImage?
    
    open var contrast:Float = 1.0
    open var brightness:Float = 0.0
    open var saturation:Float = 1.0
    
    /// Returns a CIImage object that encapsulates the operations configured in the filter. (read-only)
    open override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        guard let contrastFilter = CIFilter(name: "CIColorControls") else {
            return inputImage
        }
        
        contrastFilter.setValue(contrast, forKey: "inputContrast")
        contrastFilter.setValue(brightness, forKey: "inputBrightness")
        contrastFilter.setValue(saturation, forKey: "inputSaturation")
        contrastFilter.setValue(inputImage, forKey: kCIInputImageKey)
        return contrastFilter.outputImage
    }
}

extension IMGLYContrastBrightnessSaturationFilter {
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! IMGLYContrastBrightnessSaturationFilter
        copy.inputImage = inputImage?.copy(with: zone) as? CIImage
        copy.contrast = contrast
        copy.brightness = brightness
        copy.saturation = saturation
        return copy
    }
}
