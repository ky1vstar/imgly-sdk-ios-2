//
//  IMGLYActionButton.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 07/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public typealias IMGLYActionButtonHandler = () -> (Void)
public typealias IMGLYShowSelectionBlock = () -> (Bool)

open class IMGLYActionButton {
    let title: String?
    let image: UIImage?
    let selectedImage: UIImage?
    let handler: IMGLYActionButtonHandler
    let showSelection: IMGLYShowSelectionBlock?
    let isEnabled: Bool?
        
    init(title: String?, image: UIImage?, selectedImage: UIImage? = nil, handler: @escaping IMGLYActionButtonHandler, showSelection: IMGLYShowSelectionBlock? = nil, isEnabled: Bool? = true) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage
        self.handler = handler
        self.showSelection = showSelection
        self.isEnabled = isEnabled
    }
}
