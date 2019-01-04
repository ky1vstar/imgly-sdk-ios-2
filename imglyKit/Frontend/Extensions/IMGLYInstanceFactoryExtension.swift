//
//  IMGLYInstanceFactoryExtension.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 30/05/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation
import CoreGraphics

extension IMGLYInstanceFactory {
    // MARK: - Editor View Controllers
    
    /**
    Return the viewcontroller according to the button-type.
    This is used by the main menu.
    
    - parameter type: The type of the button pressed.
    
    - returns: A viewcontroller according to the button-type.
    */
    public class func viewControllerForButtonType(_ type: IMGLYMainMenuButtonType, withFixedFilterStack fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYSubEditorViewController? {
        switch (type) {
        case IMGLYMainMenuButtonType.filter:
            return filterEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.stickers:
            return stickersEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.orientation:
            return orientationEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.focus:
            return focusEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.crop:
            return cropEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.brightness:
            return brightnessEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.contrast:
            return contrastEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.saturation:
            return saturationEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        case IMGLYMainMenuButtonType.text:
            return textEditorViewControllerWithFixedFilterStack(fixedFilterStack)
        default:
            return nil
        }
    }
    
    public class func filterEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYFilterEditorViewController {
        return IMGLYFilterEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func stickersEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYStickersEditorViewController {
        return IMGLYStickersEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func orientationEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYOrientationEditorViewController {
        return IMGLYOrientationEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func focusEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYFocusEditorViewController {
        return IMGLYFocusEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func cropEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYCropEditorViewController {
        return IMGLYCropEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func brightnessEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYBrightnessEditorViewController {
        return IMGLYBrightnessEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func contrastEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYContrastEditorViewController {
        return IMGLYContrastEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func saturationEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYSaturationEditorViewController {
        return IMGLYSaturationEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    public class func textEditorViewControllerWithFixedFilterStack(_ fixedFilterStack: IMGLYFixedFilterStack) -> IMGLYTextEditorViewController {
        return IMGLYTextEditorViewController(fixedFilterStack: fixedFilterStack)
    }
    
    // MARK: - Gradient Views
    
    public class func circleGradientView() -> IMGLYCircleGradientView {
        return IMGLYCircleGradientView(frame: CGRect.zero)
    }
    
    public class func boxGradientView() -> IMGLYBoxGradientView {
        return IMGLYBoxGradientView(frame: CGRect.zero)
    }
    
    // MARK: - Helpers
    
    public class func cropRectComponent() -> IMGLYCropRectComponent {
        return IMGLYCropRectComponent()
    }
}
