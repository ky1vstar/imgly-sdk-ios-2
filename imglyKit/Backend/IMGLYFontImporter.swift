//
//  IMGLYFontImporter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 09/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreText

/**
  Provides functions to import font added as resource. It also registers them,
  so that the application can load them like any other pre-installed font.
*/
open class IMGLYFontImporter {
    fileprivate static var fontsRegistered = false
    
    /**
    Imports all fonts added as resource. Supported formats are TTF and OTF.
    */
    open func importFonts() {
        if !IMGLYFontImporter.fontsRegistered {
            importFontsWithExtension("ttf")
            importFontsWithExtension("otf")
            IMGLYFontImporter.fontsRegistered = true
        }
    }
    
    fileprivate func importFontsWithExtension(_ ext: String) {
        let paths = Bundle(for: type(of: self)).paths(forResourcesOfType: ext, inDirectory: nil)
        for fontPath in paths {
            let data: Data? = FileManager.default.contents(atPath: fontPath)
            var error: Unmanaged<CFError>?
            let provider = CGDataProvider(data: data! as CFData)
            let font = CGFont(provider!)
            
            if (!CTFontManagerRegisterGraphicsFont(font!, &error)) {
                print("Failed to register font, error: \(String(describing: error))")
                return
            }
        }
    }
}
