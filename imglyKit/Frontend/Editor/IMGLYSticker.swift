//
//  IMGLYSticker.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 24/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYSticker: NSObject {
    open let image: UIImage
    open let thumbnail: UIImage?
    
    public init(image: UIImage, thumbnail: UIImage?) {
        self.image = image
        self.thumbnail = thumbnail
        super.init()
    }
}
