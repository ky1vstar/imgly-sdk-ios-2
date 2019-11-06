//
//  IMGLYEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 07/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

internal let PhotoProcessorQueue = DispatchQueue(label: "ly.img.SDK.PhotoProcessor", attributes: [])

open class IMGLYEditorViewController: UIViewController {
    
    // MARK: - Properties
    
    open var shouldShowActivityIndicator = true
    
    open var updating = false {
        didSet {
            if shouldShowActivityIndicator {
                DispatchQueue.main.async {
                    if self.updating {
                        self.activityIndicatorView.startAnimating()
                    } else {
                        self.activityIndicatorView.stopAnimating()
                    }
                }
            }
        }
    }
    
    open var lowResolutionImage: UIImage?
    
    open fileprivate(set) lazy var previewImageView: IMGLYZoomingImageView = {
        let imageView = IMGLYZoomingImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = self.enableZoomingInPreviewImage
        return imageView
        }()
    
    open fileprivate(set) lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        configureViewHierarchy()
        configureViewConstraints()
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    open override var prefersStatusBarHidden : Bool {
        return true
    }
    
    open override var shouldAutorotate : Bool {
        return false
    }
    
    open override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .portrait
    }
    
    // MARK: - Configuration
    
    fileprivate func configureNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(IMGLYEditorViewController.tappedDone(_:)))
    }
    
    fileprivate func configureViewHierarchy() {
        view.backgroundColor = UIColor.black

        view.addSubview(previewImageView)
        view.addSubview(bottomContainerView)
        previewImageView.addSubview(activityIndicatorView)
    }
    
    fileprivate func configureViewConstraints() {
        let views: [String: AnyObject] = [
            "previewImageView" : previewImageView,
            "bottomContainerView" : bottomContainerView,
            "topLayoutGuide" : topLayoutGuide
        ]
        
        let metrics: [String: AnyObject] = [
            "bottomContainerViewHeight" : 100 as AnyObject
        ]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[previewImageView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[bottomContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topLayoutGuide][previewImageView][bottomContainerView(==bottomContainerViewHeight)]|", options: [], metrics: metrics, views: views))
        
        previewImageView.addConstraint(NSLayoutConstraint(item: activityIndicatorView, attribute: .centerX, relatedBy: .equal, toItem: previewImageView, attribute: .centerX, multiplier: 1, constant: 0))
        previewImageView.addConstraint(NSLayoutConstraint(item: activityIndicatorView, attribute: .centerY, relatedBy: .equal, toItem: previewImageView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    open var enableZoomingInPreviewImage: Bool {
        // Subclasses should override this to enable zooming
        return false
    }
    
    // MARK: - Actions
    
    @objc open func tappedDone(_ sender: UIBarButtonItem?) {
        // Subclasses must override this
    }
    
}
