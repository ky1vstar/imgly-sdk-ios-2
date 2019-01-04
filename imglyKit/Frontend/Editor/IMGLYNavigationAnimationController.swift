//
//  IMGLYNavigationAnimationController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 08/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

class IMGLYNavigationAnimationController: NSObject {
}

extension IMGLYNavigationAnimationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        
        if let fromViewController = fromViewController, let toViewController = toViewController {
            let toView = toViewController.view
            let fromView = fromViewController.view
            
            let containerView = transitionContext.containerView
            containerView.addSubview(toView!)
            containerView.sendSubview(toBack: toView!)
            
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration, animations: {
                fromView?.alpha = 0
                }, completion: { finished in
                    if transitionContext.transitionWasCancelled {
                        fromView?.alpha = 1
                    } else {
                        fromView?.removeFromSuperview()
                        fromView?.alpha = 1
                    }
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
