//
//  IMGLYSticker.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 24/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import Gifu
import ImageIO

open class IMGLYSticker: NSObject {
    public let image: UIImage?
    public let dataGif: Data?
    public var resultImage: UIImage?
    public var tags: [String]?
    
    public init(image: UIImage? = nil, dataGif: Data? = nil, tags: [String]?) {
        self.image = image
        self.dataGif = dataGif
        self.resultImage = image
        self.tags = tags
        super.init()
    }
    
    var animatedFrames: [UIImage] {
        guard let dataGif = self.dataGif else {
            return []
        }
        
        let gifOptions = [
            kCGImageSourceShouldAllowFloat as String : true as NSNumber,
            kCGImageSourceCreateThumbnailWithTransform as String : true as NSNumber,
            kCGImageSourceCreateThumbnailFromImageAlways as String : true as NSNumber
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(dataGif as CFData, gifOptions) else {
            debugPrint("Cannot create image source with data!")
            return []
        }
        
        let framesCount = CGImageSourceGetCount(imageSource)
        var frameList = [UIImage]()
        
        for index in 0 ..< framesCount {
            if let cgImageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) {
                let uiImageRef = UIImage(cgImage: cgImageRef)
                frameList.append(uiImageRef)
            }
        }
        return frameList
    }
  
}

