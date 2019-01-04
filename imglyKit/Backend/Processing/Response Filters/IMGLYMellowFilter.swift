//
//  IMGLYMellowFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

open class IMGLYMellowFilter: IMGLYResponseFilter {
    @objc init() {
        super.init(responseName: "Mellow")
        self.imgly_displayName = "Mellow"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override var filterType:IMGLYFilterType {
        get {
            return IMGLYFilterType.mellow
        }
    }
}
