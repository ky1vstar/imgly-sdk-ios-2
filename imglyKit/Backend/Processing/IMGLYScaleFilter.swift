//
//  IMGLYScaleFilter.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 24/06/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

#if os(iOS)
    import CoreImage
    #elseif os(OSX)
    import AppKit
    import QuartzCore
#endif

open class IMGLYScaleFilter: CIFilter {
    open var inputImage: CIImage?
    open var scale = Float(1)
    
    /// Returns a CIImage object that encapsulates the operations configured in the filter. (read-only)
    open override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            return inputImage
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        
        return filter.outputImage
    }
}

extension IMGLYScaleFilter {
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! IMGLYScaleFilter
        copy.inputImage = inputImage?.copy(with: zone) as? CIImage
        copy.scale = scale
        return copy
    }
}
