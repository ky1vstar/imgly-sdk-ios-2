//
//  IMGLYPhotoProcessor.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 03/02/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation
#if os(iOS)
import CoreImage
import UIKit
#elseif os(OSX)
import QuartzCore
import AppKit
#endif

/**
All types of response-filters.
*/
@objc public enum IMGLYFilterType: Int {
    case none,
    k1,
    k2,
    k6,
    kDynamic,
    fridge,
    breeze,
    orchid,
    chest,
    front,
    fixie,
    x400,
    bw,
    ad1920,
    lenin,
    quozi,
    pola669,
    polaSX,
    food,
    glam,
    celsius,
    texas,
    lomo,
    goblin,
    sin,
    mellow,
    soft,
    blues,
    elder,
    sunset,
    evening,
    steel,
    seventies,
    highContrast,
    blueShadows,
    highcarb,
    eighties,
    colorful,
    lomo100,
    pro400,
    twilight,
    cottonCandy,
    pale,
    settled,
    cool,
    litho,
    ancient,
    pitched,
    lucid,
    creamy,
    keen,
    tender,
    bleached,
    bleachedBlue,
    fall,
    winter,
    sepiaHigh,
    summer,
    classic,
    noGreen,
    neat,
    plate
}

open class IMGLYPhotoProcessor {
    open class func processWithCIImage(_ image: CIImage, filters: [CIFilter]) -> CIImage? {
        if filters.count == 0 {
            return image
        }
        
        var currentImage: CIImage? = image
        
        for filter in filters {
            filter.setValue(currentImage, forKey:kCIInputImageKey)
            
            currentImage = filter.outputImage
        }
        
        if let currentImage = currentImage, currentImage.extent.isEmpty {
            return nil
        }
        
        return currentImage
    }
    
    #if os(iOS)
    
    open class func processWithUIImage(_ image: UIImage, filters: [CIFilter]) -> UIImage? {
        let imageOrientation = image.imageOrientation
        guard let coreImage = CIImage(image: image) else {
            return nil
        }
        
        let filteredCIImage = processWithCIImage(coreImage, filters: filters)
        let filteredCGImage = CIContext(options: nil).createCGImage(filteredCIImage!, from: filteredCIImage!.extent)
        return UIImage(cgImage: filteredCGImage!, scale: 1.0, orientation: imageOrientation)
    }
    
    #elseif os(OSX)

    public class func processWithNSImage(image: NSImage, filters: [CIFilter]) -> NSImage? {
        if let tiffRepresentation = image.tiffRepresentation, let image = CIImage(data: tiffRepresentation) {
            let filteredCIImage = processWithCIImage(image, filters: filters)
            
            if let filteredCIImage = filteredCIImage {
                let rep = NSCIImageRep(ciImage: filteredCIImage)
                let image = NSImage(size: NSSize(width: filteredCIImage.extent.size.width, height: filteredCIImage.extent.size.height))
                image.addRepresentation(rep)
                return image
            }
        }
        
        return nil
    }
    
    #endif
}
