//
//  IMGLYStrickersManager.swift
//  imglyKit2
//
//  Created by Dhaker Trimech on 24/05/2021.
//

import Foundation

open class IMGLYStrickersManager {
   
    public static let shared = IMGLYStrickersManager()
    open var dataArray = [IMGLYSticker?]()
    open var stickersUsed = [IMGLYGIFImageView?]()
}
