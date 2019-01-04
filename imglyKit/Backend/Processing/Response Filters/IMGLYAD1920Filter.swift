//
//  IMGLYAD1920Filter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYAD1920Filter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "AD1920")
        self.imgly_displayName = "AD1920"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.ad1920
        }
    }
}
