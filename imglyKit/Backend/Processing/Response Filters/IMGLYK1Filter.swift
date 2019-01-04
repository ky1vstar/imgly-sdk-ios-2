//
//  IMGLYK1Filter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYK1Filter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "K1")
        self.imgly_displayName = "K1"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.k1
        }
    }
}
