//
//  IMGLYColorButton.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 05/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation
import UIKit

open class IMGLYColorButton : UIButton {
    open var hasFrame = false {
        didSet {
            styleButton()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        styleButton()
    }
    
    fileprivate func styleButton() {
        isSelected = false
        layer.cornerRadius = 3
        layer.masksToBounds = true
        layer.borderWidth = 1.0 / contentScaleFactor
        let alpha = hasFrame ? 0.3 : 0.0
        layer.borderColor = UIColor(white: 1.0, alpha: CGFloat(alpha)).cgColor
    }
}
