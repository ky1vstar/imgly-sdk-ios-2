//
//  IMGLYSticker.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 24/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import Gifu

open class IMGLYSticker: NSObject {
    public let image: UIImage?
    public let dataGif: Data?
    public var resultImage: UIImage?
    
    public init(image: UIImage? = nil, dataGif: Data? = nil) {
        self.image = image
        self.dataGif = dataGif
        self.resultImage = image
        super.init()
    }
}

