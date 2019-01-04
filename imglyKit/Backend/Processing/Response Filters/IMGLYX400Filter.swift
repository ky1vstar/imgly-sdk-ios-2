//
//  IMGLYX400Filter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYX400Filter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "X400")
        self.imgly_displayName = "X400"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.x400
        }
    }
}
