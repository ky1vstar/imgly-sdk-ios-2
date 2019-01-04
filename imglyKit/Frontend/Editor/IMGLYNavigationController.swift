//
//  IMGLYNavigationController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYNavigationController: UINavigationController {

    // MARK: - UIViewController
    
    override open var shouldAutorotate : Bool {
        return false
    }
    
    override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .portrait
    }

}
