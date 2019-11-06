//
//  IMGLYEnhancementFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 09/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

#if os(iOS)
import CoreImage
#elseif os(OSX)
import QuartzCore
#endif

/**
  This class uses apples auto-enhancement filters to improve the overall
  quality of an image. Due the way this filter is used within this SDK,
  there is a mechanism that retains the enhanced image until its resetted
  and a recalculation is foced. This behaviour is inactive by default, and
  can be activated by setting 'storeEnhancedImage' to true.
*/
open class IMGLYEnhancementFilter : CIFilter {
    /// A CIImage object that serves as input for the filter.
    @objc open var inputImage:CIImage?
    
//    #if os(iOS)
    /// If this is set to false, the original image is returned.
    open var _enabled = true
//    #endif
    
    /// If this is set to true, the enhanced image is kept until reset is called.
    open var storeEnhancedImage = false
    
    fileprivate var enhancedImage: CIImage? = nil
    
    /// Returns a CIImage object that encapsulates the operations configured in the filter. (read-only)
    open override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            return nil
        }
        
        if !_enabled {
            return inputImage
        }
        
        if storeEnhancedImage {
            if enhancedImage != nil {
                return enhancedImage
            }
        }
        
        
        var intermediateImage: CIImage? = inputImage
        let filters = intermediateImage?.autoAdjustmentFilters(options: convertToOptionalCIImageAutoAdjustmentOptionDictionary([convertFromCIImageAutoAdjustmentOption(CIImageAutoAdjustmentOption.redEye):NSNumber(value: false as Bool)]))
        for filter in filters ?? [] {
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            intermediateImage = filter.outputImage
        }
        
        if storeEnhancedImage {
            enhancedImage = intermediateImage
        }
        
        return intermediateImage
    }
    
    open func reset() {
        enhancedImage = nil
    }
}

extension IMGLYEnhancementFilter {
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! IMGLYEnhancementFilter
        copy.inputImage = inputImage?.copy(with: zone) as? CIImage
        copy._enabled = _enabled
        copy.storeEnhancedImage = storeEnhancedImage
        copy.enhancedImage = enhancedImage?.copy(with: zone) as? CIImage
        return copy
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCIImageAutoAdjustmentOptionDictionary(_ input: [String: Any]?) -> [CIImageAutoAdjustmentOption: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (CIImageAutoAdjustmentOption(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCIImageAutoAdjustmentOption(_ input: CIImageAutoAdjustmentOption) -> String {
	return input.rawValue
}
