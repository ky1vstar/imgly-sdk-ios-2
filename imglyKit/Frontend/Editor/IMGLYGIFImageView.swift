//
//  IMGLYGIFImageView.swift
//  imglyKit2
//
//  Created by Dhaker Trimech on 27/05/2021.
//

import Foundation
import Gifu

public class IMGLYGIFImageView: UIImageView, GIFAnimatable {
    
    /// A lazy animator.
    public lazy var animator: Animator? = {
        return Animator(withDelegate: self)
    }()
    
    /// Layer delegate method called periodically by the layer. **Should not** be called manually.
    ///
    /// - parameter layer: The delegated layer.
    override public func display(_ layer: CALayer) {
        if UIImageView.instancesRespond(to: #selector(display(_:))) {
            super.display(layer)
        }
        updateImageIfNeeded()
    }
    
    public var sticker: IMGLYSticker?
    
}
