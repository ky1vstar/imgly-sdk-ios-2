//
//  NSImageExtension.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 30/05/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

#if os(OSX)
    
import AppKit
import CoreGraphics

public extension NSImage {
    
    @objc(CGImage)
    var cgImage: CoreGraphics.CGImage? {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)
        return cgImage
    }
    
}

#endif
