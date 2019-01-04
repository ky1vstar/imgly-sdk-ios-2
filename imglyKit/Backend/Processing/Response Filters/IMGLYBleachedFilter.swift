//
//  IMGLYBleachedFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 24/02/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYBleachedFilter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "Bleached")
        self.imgly_displayName = "Bleached"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.bleached
        }
    }
}
