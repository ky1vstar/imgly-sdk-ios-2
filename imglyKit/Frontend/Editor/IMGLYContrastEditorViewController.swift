//
//  IMGLYContrastEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 10/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYContrastEditorViewController: IMGLYSliderEditorViewController {

    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("contrast-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    // MARK: - SliderEditorViewController
    
    override open var minimumValue: Float {
        return 0
    }
    
    override open var maximumValue: Float {
        return 2
    }
    
    override open var initialValue: Float {
        return fixedFilterStack.brightnessFilter.contrast
    }
    
    override open func valueChanged(_ value: Float) {
        fixedFilterStack.brightnessFilter.contrast = slider.value
    }

}
