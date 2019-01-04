//
//  IMGLYK6Filter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYK6Filter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "K6")
        self.imgly_displayName = "K6"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.k6
        }
    }
}
