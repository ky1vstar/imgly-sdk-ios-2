//
// IMGLYNoGreenFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 28/01/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYNoGreenFilter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "NoGreen")
        self.imgly_displayName = "No Green"
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.noGreen
        }
    }
}
