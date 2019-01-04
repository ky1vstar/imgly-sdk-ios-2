//
//  IMGLYK2Filter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYK2Filter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "K2")
        self.imgly_displayName = "K2"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.k2
        }
    }
}
