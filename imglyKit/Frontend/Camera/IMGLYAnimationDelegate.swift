//
//  IMGLYAnimationDelegate.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 11/05/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import QuartzCore

public typealias IMGLYAnimationDelegateBlock = (Bool) -> (Void)

open class IMGLYAnimationDelegate: NSObject, CAAnimationDelegate {
    
    // MARK: - Properties
    
    open let block: IMGLYAnimationDelegateBlock
    
    // MARK: - Initializers
    
    init(block: @escaping IMGLYAnimationDelegateBlock) {
        self.block = block
    }
    
    // MARK: - Animation Delegate
    
    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        block(flag)
    }
}
