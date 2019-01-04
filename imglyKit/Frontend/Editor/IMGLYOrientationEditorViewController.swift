//
//  IMGLYOrientationEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYOrientationEditorViewController: IMGLYSubEditorViewController {
    
    // MARK: - Properties
    
    open fileprivate(set) lazy var rotateLeftButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("orientation-editor.rotate-left", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_orientation_rotate-l", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYOrientationEditorViewController.rotateLeft(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var rotateRightButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("orientation-editor.rotate-right", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_orientation_rotate-r", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYOrientationEditorViewController.rotateRight(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var flipHorizontallyButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("orientation-editor.flip-horizontally", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_orientation_flip-h", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYOrientationEditorViewController.flipHorizontally(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var flipVerticallyButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("orientation-editor.flip-vertically", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_orientation_flip-v", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYOrientationEditorViewController.flipVertically(_:)), for: .touchUpInside)
        return button
        }()
    
    fileprivate lazy var transparentRectView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        return view
        }()
    
    fileprivate let cropRectComponent = IMGLYInstanceFactory.cropRectComponent()
    fileprivate var cropRectLeftBound = CGFloat(0)
    fileprivate var cropRectRightBound = CGFloat(0)
    fileprivate var cropRectTopBound = CGFloat(0)
    fileprivate var cropRectBottomBound = CGFloat(0)
    
    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("orientation-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        configureButtons()
        configureCropRect()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let cropRect = fixedFilterStack.orientationCropFilter.cropRect
        if cropRect.origin.x != 0 || cropRect.origin.y != 0 ||
            cropRect.size.width != 1.0 || cropRect.size.height != 1.0 {
                updatePreviewImageWithoutCropWithCompletion {
                    self.view.layoutIfNeeded()
                    self.cropRectComponent.present()
                    self.layoutCropRectViews()
                }
        } else {
            layoutCropRectViews()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        transparentRectView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
        reCalculateCropRectBounds()
    }
    
    // MARK: - IMGLYEditorViewController
    
    open override var enableZoomingInPreviewImage: Bool {
        return true
    }
    
    // MARK: - SubEditorViewController
    
    open override func tappedDone(_ sender: UIBarButtonItem?) {
        updatePreviewImageWithCompletion {
            super.tappedDone(sender)
        }
    }
    
    // MARK: - Configuration
    
    fileprivate func configureButtons() {
        let buttonContainerView = UIView()
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonContainerView)
        
        buttonContainerView.addSubview(rotateLeftButton)
        buttonContainerView.addSubview(rotateRightButton)
        buttonContainerView.addSubview(flipHorizontallyButton)
        buttonContainerView.addSubview(flipVerticallyButton)
        
        let views = [
            "buttonContainerView" : buttonContainerView,
            "rotateLeftButton" : rotateLeftButton,
            "rotateRightButton" : rotateRightButton,
            "flipHorizontallyButton" : flipHorizontallyButton,
            "flipVerticallyButton" : flipVerticallyButton
        ]
        
        let metrics = [
            "buttonWidth" : 70
        ]
        
        // Button Constraints
        
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[rotateLeftButton(==buttonWidth)][rotateRightButton(==rotateLeftButton)][flipHorizontallyButton(==rotateLeftButton)][flipVerticallyButton(==rotateLeftButton)]|", options: [], metrics: metrics, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[rotateLeftButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[rotateRightButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[flipHorizontallyButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[flipVerticallyButton]|", options: [], metrics: nil, views: views))
        
        // Container Constraints
        
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[buttonContainerView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraint(NSLayoutConstraint(item: buttonContainerView, attribute: .centerX, relatedBy: .equal, toItem: bottomContainerView, attribute: .centerX, multiplier: 1, constant: 0))
    }
    
    fileprivate func configureCropRect() {
        view.addSubview(transparentRectView)
        cropRectComponent.cropRect = fixedFilterStack.orientationCropFilter.cropRect
        cropRectComponent.setup(transparentRectView, parentView: self.view, showAnchors: false)
    }
    
    // MARK: - Helpers
    
    fileprivate func updatePreviewImageWithoutCropWithCompletion(_ completionHandler: IMGLYPreviewImageGenerationCompletionBlock?) {
        let oldCropRect = fixedFilterStack.orientationCropFilter.cropRect
        fixedFilterStack.orientationCropFilter.cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        updatePreviewImageWithCompletion { () -> (Void) in
            self.fixedFilterStack.orientationCropFilter.cropRect = oldCropRect
            completionHandler?()
        }
    }
    
    // MARK: - Cropping
    
    fileprivate func layoutCropRectViews() {
        reCalculateCropRectBounds()
        let viewWidth = cropRectRightBound - cropRectLeftBound
        let viewHeight = cropRectBottomBound - cropRectTopBound
        let x = cropRectLeftBound + viewWidth * fixedFilterStack.orientationCropFilter.cropRect.origin.x
        let y = cropRectTopBound + viewHeight * fixedFilterStack.orientationCropFilter.cropRect.origin.y
        let width = viewWidth * fixedFilterStack.orientationCropFilter.cropRect.size.width
        let height = viewHeight * fixedFilterStack.orientationCropFilter.cropRect.size.height
        let rect = CGRect(x: x, y: y, width: width, height: height)
        cropRectComponent.cropRect = rect
        cropRectComponent.layoutViewsForCropRect()
    }
    
    fileprivate func reCalculateCropRectBounds() {
        let width = transparentRectView.frame.size.width
        let height = transparentRectView.frame.size.height
        cropRectLeftBound = (width - previewImageView.visibleImageFrame.size.width) / 2.0
        cropRectRightBound = width - cropRectLeftBound
        cropRectTopBound = (height - previewImageView.visibleImageFrame.size.height) / 2.0
        cropRectBottomBound = height - cropRectTopBound
    }
    
    fileprivate func rotateCropRectLeft() {
        moveCropRectMidToOrigin()
        // rotatate
        let tempRect = fixedFilterStack.orientationCropFilter.cropRect
        fixedFilterStack.orientationCropFilter.cropRect.origin.x = tempRect.origin.y
        fixedFilterStack.orientationCropFilter.cropRect.origin.y = -tempRect.origin.x
        fixedFilterStack.orientationCropFilter.cropRect.size.width = tempRect.size.height
        fixedFilterStack.orientationCropFilter.cropRect.size.height = -tempRect.size.width
        moveCropRectTopLeftToOrigin()
    }
    
    fileprivate func rotateCropRectRight() {
        moveCropRectMidToOrigin()
        // rotatate
        let tempRect = fixedFilterStack.orientationCropFilter.cropRect
        fixedFilterStack.orientationCropFilter.cropRect.origin.x = -tempRect.origin.y
        fixedFilterStack.orientationCropFilter.cropRect.origin.y = tempRect.origin.x
        fixedFilterStack.orientationCropFilter.cropRect.size.width = -tempRect.size.height
        fixedFilterStack.orientationCropFilter.cropRect.size.height = tempRect.size.width
        moveCropRectTopLeftToOrigin()
    }
    
    fileprivate func flipCropRectHorizontal() {
        moveCropRectMidToOrigin()
        fixedFilterStack.orientationCropFilter.cropRect.origin.x = -fixedFilterStack.orientationCropFilter.cropRect.origin.x - fixedFilterStack.orientationCropFilter.cropRect.size.width
        moveCropRectTopLeftToOrigin()
    }
    
    fileprivate func flipCropRectVertical() {
        moveCropRectMidToOrigin()
        fixedFilterStack.orientationCropFilter.cropRect.origin.y = -fixedFilterStack.orientationCropFilter.cropRect.origin.y - fixedFilterStack.orientationCropFilter.cropRect.size.height
        moveCropRectTopLeftToOrigin()
    }
    
    fileprivate func moveCropRectMidToOrigin() {
        fixedFilterStack.orientationCropFilter.cropRect.origin.x -= 0.5
        fixedFilterStack.orientationCropFilter.cropRect.origin.y -= 0.5
    }
    
    fileprivate func moveCropRectTopLeftToOrigin() {
        fixedFilterStack.orientationCropFilter.cropRect.origin.x += 0.5
        fixedFilterStack.orientationCropFilter.cropRect.origin.y += 0.5
    }

    // MARK: - Actions
    
    @objc fileprivate func rotateLeft(_ sender: IMGLYImageCaptionButton) {
        fixedFilterStack.orientationCropFilter.rotateLeft()
        rotateCropRectLeft()
        updatePreviewImageWithoutCropWithCompletion {
            self.view.layoutIfNeeded()
            self.layoutCropRectViews()
        }
    }
    
    @objc fileprivate func rotateRight(_ sender: IMGLYImageCaptionButton) {
        fixedFilterStack.orientationCropFilter.rotateRight()
        rotateCropRectRight()
        updatePreviewImageWithoutCropWithCompletion {
            self.view.layoutIfNeeded()
            self.layoutCropRectViews()
        }
    }
    
    @objc fileprivate func flipHorizontally(_ sender: IMGLYImageCaptionButton) {
        fixedFilterStack.orientationCropFilter.flipHorizontal()
        flipCropRectHorizontal()
        updatePreviewImageWithoutCropWithCompletion {
            self.layoutCropRectViews()
        }
    }
    
    @objc fileprivate func flipVertically(_ sender: IMGLYImageCaptionButton) {
        fixedFilterStack.orientationCropFilter.flipVertical()
        flipCropRectVertical()
        updatePreviewImageWithoutCropWithCompletion {
            self.layoutCropRectViews()
        }
    }
}
