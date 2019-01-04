//
//  FixedFilterStack.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 08/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import CoreImage

/**
*   This class represents the filterstack that is used when using the UI.
*   It represents a chain of filters that will be applied to the taken image.
*   That way we make sure the order of filters stays the same, and we don't need to take
*   care about creating the single filters.
*/
open class IMGLYFixedFilterStack: NSObject {
    
    // MARK: - Properties
    
    open var enhancementFilter: IMGLYEnhancementFilter = {
        let filter = IMGLYInstanceFactory.enhancementFilter()
        filter._enabled = false
        filter.storeEnhancedImage = true
        return filter
        }()
    
    open var orientationCropFilter = IMGLYInstanceFactory.orientationCropFilter()
    open var effectFilter = IMGLYInstanceFactory.effectFilterWithType(IMGLYFilterType.none)
    open var brightnessFilter = IMGLYInstanceFactory.colorAdjustmentFilter()
    open var tiltShiftFilter = IMGLYInstanceFactory.tiltShiftFilter()
    open var textFilter = IMGLYInstanceFactory.textFilter()
    open var stickerFilters = [CIFilter]()
    
    open var activeFilters: [CIFilter] {
        var activeFilters: [CIFilter] = [enhancementFilter, orientationCropFilter, tiltShiftFilter, effectFilter, brightnessFilter, textFilter]
        activeFilters += stickerFilters
        
        return activeFilters
    }
    
    // MARK: - Initializers
    
    required override public init () {
        super.init()
    }
}

extension IMGLYFixedFilterStack: NSCopying {
    public func copy(with zone: NSZone?) -> Any {
        let copy = type(of: self).init()
        copy.enhancementFilter = enhancementFilter.copy(with: zone) as! IMGLYEnhancementFilter
        copy.orientationCropFilter = orientationCropFilter.copy(with: zone) as! IMGLYOrientationCropFilter
        copy.effectFilter = effectFilter.copy(with: zone) as! IMGLYResponseFilter
        copy.brightnessFilter = brightnessFilter.copy(with: zone) as! IMGLYContrastBrightnessSaturationFilter
        copy.tiltShiftFilter = tiltShiftFilter.copy(with: zone) as! IMGLYTiltshiftFilter
        copy.textFilter = textFilter.copy(with: zone) as! IMGLYTextFilter
        copy.stickerFilters = NSArray(array: stickerFilters, copyItems: true) as! [CIFilter]
        return copy
    }
}
