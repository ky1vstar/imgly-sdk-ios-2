//
//  IMGLYInstanceFactory.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 03/02/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

/**
  A singleton that is out to create objects. It is used within the SDK to 
  create filters, views, viewcontrollers and such.
*/
open class IMGLYInstanceFactory {
    /**
    Creates a response filter with the specified type.
    
    - parameter type: The type of the filter that should be created.
    
    - returns: A CIFilter object that realizes the desired filter.
    */
    open class func effectFilterWithType(_ type: IMGLYFilterType) -> IMGLYResponseFilter {
        switch(type) {
        case .none:
            return IMGLYNoneFilter()
        case .k1:
            return IMGLYK1Filter()
        case .k2:
            return IMGLYK2Filter()
        case .k6:
            return IMGLYK6Filter()
        case .kDynamic:
            return IMGLYKDynamicFilter()
        case .fridge:
            return IMGLYFridgeFilter()
        case .breeze:
            return IMGLYBreezeFilter()
        case .orchid:
            return IMGLYOrchidFilter()
        case .chest:
            return IMGLYChestFilter()
        case .front:
            return IMGLYFrontFilter()
        case .fixie:
            return IMGLYFixieFilter()
        case .x400:
            return IMGLYX400Filter()
        case .bw:
            return IMGLYBWFilter()
        case .ad1920:
            return IMGLYAD1920Filter()
        case .lenin:
            return IMGLYLeninFilter()
        case .quozi:
            return IMGLYQuoziFilter()
        case .pola669:
            return IMGLYPola669Filter()
        case .polaSX:
            return IMGLYPolaSXFilter()
        case .food:
            return IMGLYFoodFilter()
        case .glam:
            return IMGLYGlamFilter()
        case .celsius:
            return IMGLYCelsiusFilter()
        case .texas:
            return IMGLYTexasFilter()
        case .lomo:
            return IMGLYLomoFilter()
        case .goblin:
            return IMGLYGoblinFilter()
        case .sin:
            return IMGLYSinFilter()
        case .mellow:
            return IMGLYMellowFilter()
        case .soft:
            return IMGLYSoftFilter()
        case .blues:
            return IMGLYBluesFilter()
        case .elder:
            return IMGLYElderFilter()
        case .sunset:
            return IMGLYSunsetFilter()
        case .evening:
            return IMGLYEveningFilter()
        case .steel:
            return IMGLYSteelFilter()
        case .seventies:
            return IMGLYSeventiesFilter()
        case .highContrast:
            return IMGLYHighContrastFilter()
        case .blueShadows:
            return IMGLYBlueShadowsFilter()
        case .highcarb:
            return IMGLYHighcarbFilter()
        case .eighties:
            return IMGLYEightiesFilter()
        case .colorful:
            return IMGLYColorfulFilter()
        case .lomo100:
            return IMGLYLomo100Filter()
        case .pro400:
            return IMGLYPro400Filter()
        case .twilight:
            return IMGLYTwilightFilter()
        case .cottonCandy:
            return IMGLYCottonCandyFilter()
        case .pale:
            return IMGLYPaleFilter()
        case .settled:
            return IMGLYSettledFilter()
        case .cool:
            return IMGLYCoolFilter()
        case .litho:
            return IMGLYLithoFilter()
        case .ancient:
            return IMGLYAncientFilter()
        case .pitched:
            return IMGLYPitchedFilter()
        case .lucid:
            return IMGLYLucidFilter()
        case .creamy:
            return IMGLYCreamyFilter()
        case .keen:
            return IMGLYKeenFilter()
        case .tender:
            return IMGLYTenderFilter()
        case .bleached:
            return IMGLYBleachedFilter()
        case .bleachedBlue:
            return IMGLYBleachedBlueFilter()
        case .fall:
            return IMGLYFallFilter()
        case .winter:
            return IMGLYWinterFilter()
        case .sepiaHigh:
            return IMGLYSepiaHighFilter()
        case .summer:
            return IMGLYSummerFilter()
        case .classic:
            return IMGLYClassicFilter()
        case .noGreen:
            return IMGLYNoGreenFilter()
        case .neat:
            return IMGLYNeatFilter()
        case .plate:
            return IMGLYPlateFilter()
        }
    }
    
    /**
    Creates a text filter.
    
    - returns: A text filter
    */
    open class func textFilter() -> IMGLYTextFilter {
        return IMGLYTextFilter()
    }
    
    /**
    Creates a sticker filter.
    
    - returns: A sticker filter
    */
    open class func stickerFilter() -> IMGLYStickerFilter {
        return IMGLYStickerFilter()
    }

    /**
    Creates a crop filter.
    
    - returns: A crop filter
    */
    open class func orientationCropFilter() -> IMGLYOrientationCropFilter {
        return IMGLYOrientationCropFilter()
    }
    
    /**
    Creates a tiltshift filter.
    
    - returns: A tiltshift filter.
    */
    open class func tiltShiftFilter() -> IMGLYTiltshiftFilter {
        return IMGLYTiltshiftFilter()
    }
    
    /**
    Creates a color-adjustment filter.
    
    - returns: A color-adjustment filter.
    */
    open class func colorAdjustmentFilter() -> IMGLYContrastBrightnessSaturationFilter {
        return IMGLYContrastBrightnessSaturationFilter()
    }
    
    /**
    Creates an enhancement filter.
    
    - returns: A enhancement filter.
    */
    open class func enhancementFilter() -> IMGLYEnhancementFilter {
        return IMGLYEnhancementFilter()
    }
    
    /**
    Creates an scale filter.
    
    - returns: A scale filter.
    */
    open class func scaleFilter() -> IMGLYScaleFilter {
        return IMGLYScaleFilter()
    }
    
    /**
    Returns the list of filters, that should be available in the dialogs.
    Change this list to select the set of filters you want to present to the user.
    - returns: An array of filter types.
    */
    open class var availableFilterList: [IMGLYFilterType] {
        return [
            .none,
            .k1,
            .k2,
            .k6,
            .kDynamic,
            .fridge,
            .breeze,
            .orchid,
            .chest,
            .front,
            .fixie,
            .x400,
            .bw,
            .ad1920,
            .lenin,
            .quozi,
            .pola669,
            .polaSX,
            .food,
            .glam,
            .celsius,
            .texas,
            .lomo,
            .goblin,
            .sin,
            .mellow,
            .soft,
            .blues,
            .elder,
            .sunset,
            .evening,
            .steel,
            .seventies,
            .highContrast,
            .blueShadows,
            .highcarb,
            .eighties,
            .colorful,
            .lomo100,
            .pro400,
            .twilight,
            .cottonCandy,
            .pale,
            .settled,
            .cool,
            .litho,
            .ancient,
            .pitched,
            .lucid,
            .creamy,
            .keen,
            .tender,
            .bleached,
            .bleachedBlue,
            .fall,
            .winter,
            .sepiaHigh,
            .summer,
            .classic,
            .noGreen,
            .neat,
            .plate
        ]
    }
    
    // MARK: - Font Related
    
    /**
    Returns a list that determins what fonts will be available within
    the text-dialog.
    
    - returns: An array of fontnames.
    */
    open class var availableFontsList: [String] {
        return [
            "AmericanTypewriter",
            "Avenir-Heavy",
            "ChalkboardSE-Regular",
            "ArialMT",
            "BanglaSangamMN",
            "Liberator",
            "Muncie",
            "Abraham Lincoln",
            "Airship 27",
            "Arvil",
            "Bender",
            "Blanch",
            "Cubano",
            "Franchise",
            "Geared Slab",
            "Governor",
            "Haymaker",
            "Homestead",
            "Maven Pro Light",
            "Mensch",
            "Sullivan",
            "Tommaso",
            "Valencia",
            "Vevey"
        ]
    }
    
    open class func fontImporter() -> IMGLYFontImporter {
        return IMGLYFontImporter()
    }    

}
