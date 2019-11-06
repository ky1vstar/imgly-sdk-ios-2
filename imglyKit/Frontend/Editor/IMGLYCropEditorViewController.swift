//
//  IMGLYCropEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

@objc public enum IMGLYSelectionMode: Int {
    case free
    case oneToOne
    case fourToThree
    case sixteenToNine
}

public let MinimumCropSize = CGFloat(50)

open class IMGLYCropEditorViewController: IMGLYSubEditorViewController {

    // MARK: - Properties
    
    open fileprivate(set) lazy var freeRatioButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("crop-editor.free", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_custom", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYCropEditorViewController.activateFreeRatio(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var oneToOneRatioButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("crop-editor.1-to-1", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_square", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYCropEditorViewController.activateOneToOneRatio(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var fourToThreeRatioButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("crop-editor.4-to-3", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_4-3", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYCropEditorViewController.activateFourToThreeRatio(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var sixteenToNineRatioButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("crop-editor.16-to-9", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_crop_16-9", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYCropEditorViewController.activateSixteenToNineRatio(_:)), for: .touchUpInside)
        return button
        }()
    
    fileprivate var selectedButton: IMGLYImageCaptionButton? {
        willSet(newSelectedButton) {
            self.selectedButton?.isSelected = false
        }
        
        didSet {
            self.selectedButton?.isSelected = true
        }
    }
    
    fileprivate lazy var transparentRectView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        return view
        }()
    
    fileprivate let cropRectComponent = IMGLYInstanceFactory.cropRectComponent()
    open var selectionMode = IMGLYSelectionMode.free
    open var selectionRatio = CGFloat(1.0)
    fileprivate var cropRectLeftBound = CGFloat(0)
    fileprivate var cropRectRightBound = CGFloat(0)
    fileprivate var cropRectTopBound = CGFloat(0)
    fileprivate var cropRectBottomBound = CGFloat(0)
    fileprivate var dragOffset = CGPoint.zero

    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("crop-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        configureButtons()
        configureCropRect()
        selectedButton = freeRatioButton
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        let cropRect = fixedFilterStack.orientationCropFilter.cropRect
        if cropRect.origin.x != 0 || cropRect.origin.y != 0 ||
            cropRect.size.width != 1.0 || cropRect.size.height != 1.0 {
                updatePreviewImageWithoutCropWithCompletion {
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    self.reCalculateCropRectBounds()
                    self.setInitialCropRect()
                    self.cropRectComponent.present()
                }
        } else {
            reCalculateCropRectBounds()
            setInitialCropRect()
            cropRectComponent.present()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        transparentRectView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
        reCalculateCropRectBounds()
    }
    
    // MARK: - SubEditorViewController
    
    open override func tappedDone(_ sender: UIBarButtonItem?) {
        fixedFilterStack.orientationCropFilter.cropRect = normalizedCropRect()
        
        updatePreviewImageWithCompletion {
            super.tappedDone(sender)
        }
    }
    
    // MARK: - Configuration
    
    fileprivate func configureButtons() {
        let buttonContainerView = UIView()
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonContainerView)
        
        buttonContainerView.addSubview(freeRatioButton)
        buttonContainerView.addSubview(oneToOneRatioButton)
        buttonContainerView.addSubview(fourToThreeRatioButton)
        buttonContainerView.addSubview(sixteenToNineRatioButton)
        
        let views = [
            "buttonContainerView" : buttonContainerView,
            "freeRatioButton" : freeRatioButton,
            "oneToOneRatioButton" : oneToOneRatioButton,
            "fourToThreeRatioButton" : fourToThreeRatioButton,
            "sixteenToNineRatioButton" : sixteenToNineRatioButton
        ]
        
        let metrics = [
            "buttonWidth" : 70
        ]
        
        // Button Constraints
        
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[freeRatioButton(==buttonWidth)][oneToOneRatioButton(==freeRatioButton)][fourToThreeRatioButton(==freeRatioButton)][sixteenToNineRatioButton(==freeRatioButton)]|", options: [], metrics: metrics, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[freeRatioButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[oneToOneRatioButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[fourToThreeRatioButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[sixteenToNineRatioButton]|", options: [], metrics: nil, views: views))
        
        // Container Constraints
        
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[buttonContainerView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraint(NSLayoutConstraint(item: buttonContainerView, attribute: .centerX, relatedBy: .equal, toItem: bottomContainerView, attribute: .centerX, multiplier: 1, constant: 0))
    }
    
    fileprivate func configureCropRect() {
        view.addSubview(transparentRectView)
        cropRectComponent.cropRect = fixedFilterStack.orientationCropFilter.cropRect
        cropRectComponent.setup(transparentRectView, parentView: self.view, showAnchors: true)
        addGestureRecognizerToTransparentView()
        addGestureRecognizerToAnchors()
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
    
    fileprivate func addGestureRecognizerToTransparentView() {
        transparentRectView.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(IMGLYCropEditorViewController.handlePan(_:)))
        transparentRectView.addGestureRecognizer(panGestureRecognizer)
    }
    
    fileprivate func addGestureRecognizerToAnchors() {
        addGestureRecognizerToAnchor(cropRectComponent.topLeftAnchor_!)
        addGestureRecognizerToAnchor(cropRectComponent.topRightAnchor_!)
        addGestureRecognizerToAnchor(cropRectComponent.bottomRightAnchor_!)
        addGestureRecognizerToAnchor(cropRectComponent.bottomLeftAnchor_!)
    }
    
    fileprivate func addGestureRecognizerToAnchor(_ anchor: UIImageView) {
        anchor.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(IMGLYCropEditorViewController.handlePan(_:)))
        anchor.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc open func handlePan(_ recognizer:UIPanGestureRecognizer) {
        if recognizer.view!.isEqual(cropRectComponent.topRightAnchor_) {
            handlePanOnTopRight(recognizer)
        }
        else if recognizer.view!.isEqual(cropRectComponent.topLeftAnchor_) {
            handlePanOnTopLeft(recognizer)
        }
        else if recognizer.view!.isEqual(cropRectComponent.bottomLeftAnchor_) {
            handlePanOnBottomLeft(recognizer)
        }
        else if recognizer.view!.isEqual(cropRectComponent.bottomRightAnchor_) {
            handlePanOnBottomRight(recognizer)
        }
        else if recognizer.view!.isEqual(transparentRectView) {
            handlePanOnTransparentView(recognizer)
        }
    }
    
    open func handlePanOnTopLeft(_ recognizer:UIPanGestureRecognizer) {
        let location = recognizer.location(in: transparentRectView)
        var sizeX = cropRectComponent.bottomRightAnchor_!.center.x - location.x
        var sizeY = cropRectComponent.bottomRightAnchor_!.center.y - location.y
        
        sizeX = CGFloat(Int(sizeX))
        sizeY = CGFloat(Int(sizeY))
        var size = CGSize(width: sizeX, height: sizeY)
        size = applyMinimumAreaRuleToSize(size)
        size = reCalulateSizeForTopLeftAnchor(size)
        var center = cropRectComponent.topLeftAnchor_!.center
        center.x += (cropRectComponent.cropRect.size.width - size.width)
        center.y += (cropRectComponent.cropRect.size.height - size.height)
        cropRectComponent.topLeftAnchor_!.center = center
        recalculateCropRectFromTopLeftAnchor()
        cropRectComponent.layoutViewsForCropRect()
    }
    
    fileprivate func reCalulateSizeForTopLeftAnchor(_ size:CGSize) -> CGSize {
        var newSize = size
        if selectionMode != IMGLYSelectionMode.free {
            newSize.height = newSize.height * selectionRatio
            if newSize.height > newSize.width {
                newSize.width = newSize.height
            }
            newSize.height = newSize.width / selectionRatio
            
            if (cropRectComponent.bottomRightAnchor_!.center.x - newSize.width) < cropRectLeftBound {
                newSize.width = cropRectComponent.bottomRightAnchor_!.center.x - cropRectLeftBound
                newSize.height = newSize.width / selectionRatio
            }
            if (cropRectComponent.bottomRightAnchor_!.center.y - newSize.height) < cropRectTopBound {
                newSize.height = cropRectComponent.bottomRightAnchor_!.center.y - cropRectTopBound
                newSize.width = newSize.height * selectionRatio
            }
        }
        else {
            if (cropRectComponent.bottomRightAnchor_!.center.x - newSize.width) < cropRectLeftBound {
                newSize.width = cropRectComponent.bottomRightAnchor_!.center.x - cropRectLeftBound
            }
            if (cropRectComponent.bottomRightAnchor_!.center.y - newSize.height) < cropRectTopBound {
                newSize.height = cropRectComponent.bottomRightAnchor_!.center.y - cropRectTopBound
            }
        }
        return newSize
    }
    
    fileprivate func recalculateCropRectFromTopLeftAnchor() {
        cropRectComponent.cropRect = CGRect(x: cropRectComponent.topLeftAnchor_!.center.x,
            y: cropRectComponent.topLeftAnchor_!.center.y,
            width: cropRectComponent.bottomRightAnchor_!.center.x - cropRectComponent.topLeftAnchor_!.center.x,
            height: cropRectComponent.bottomRightAnchor_!.center.y - cropRectComponent.topLeftAnchor_!.center.y)
    }
    
    fileprivate func handlePanOnTopRight(_ recognizer:UIPanGestureRecognizer) {
        let location = recognizer.location(in: transparentRectView)
        var sizeX = cropRectComponent.bottomLeftAnchor_!.center.x - location.x
        var sizeY = cropRectComponent.bottomLeftAnchor_!.center.y - location.y
        
        sizeX = CGFloat(abs(Int(sizeX)))
        sizeY = CGFloat(abs(Int(sizeY)))
        var size = CGSize(width: sizeX, height: sizeY)
        size = applyMinimumAreaRuleToSize(size)
        size = reCalulateSizeForTopRightAnchor(size)
        var center = cropRectComponent.topRightAnchor_!.center
        center.x = (cropRectComponent.bottomLeftAnchor_!.center.x + size.width)
        center.y = (cropRectComponent.bottomLeftAnchor_!.center.y - size.height)
        cropRectComponent.topRightAnchor_!.center = center
        recalculateCropRectFromTopRightAnchor()
        cropRectComponent.layoutViewsForCropRect()
    }
    
    fileprivate func reCalulateSizeForTopRightAnchor(_ size:CGSize) -> CGSize {
        var newSize = size
        if selectionMode != IMGLYSelectionMode.free {
            newSize.height = newSize.height * selectionRatio
            if newSize.height > newSize.width {
                newSize.width = newSize.height
            }
            if (cropRectComponent.topLeftAnchor_!.center.x + newSize.width) > cropRectRightBound {
                newSize.width = cropRectRightBound - cropRectComponent.topLeftAnchor_!.center.x
            }
            newSize.height = newSize.width / selectionRatio
            if (cropRectComponent.bottomRightAnchor_!.center.y - newSize.height) < cropRectTopBound {
                newSize.height = cropRectComponent.bottomRightAnchor_!.center.y - cropRectTopBound
                newSize.width = newSize.height * selectionRatio
            }
        }
        else {
            if (cropRectComponent.topLeftAnchor_!.center.x + newSize.width) > cropRectRightBound {
                newSize.width = cropRectRightBound - cropRectComponent.topLeftAnchor_!.center.x;
            }
            if (cropRectComponent.bottomRightAnchor_!.center.y - newSize.height) < cropRectTopBound {
                newSize.height =  cropRectComponent.bottomRightAnchor_!.center.y - cropRectTopBound
            }
        }
        return newSize
    }
    
    fileprivate func recalculateCropRectFromTopRightAnchor() {
        cropRectComponent.cropRect = CGRect(x: cropRectComponent.bottomLeftAnchor_!.center.x,
            y: cropRectComponent.topRightAnchor_!.center.y,
            width: cropRectComponent.topRightAnchor_!.center.x - cropRectComponent.bottomLeftAnchor_!.center.x,
            height: cropRectComponent.bottomLeftAnchor_!.center.y - cropRectComponent.topRightAnchor_!.center.y)
    }
    
    
    fileprivate func handlePanOnBottomLeft(_ recognizer:UIPanGestureRecognizer) {
        let location = recognizer.location(in: transparentRectView)
        var sizeX = cropRectComponent.topRightAnchor_!.center.x - location.x
        var sizeY = cropRectComponent.topRightAnchor_!.center.y - location.y
        
        sizeX = CGFloat(abs(Int(sizeX)))
        sizeY = CGFloat(abs(Int(sizeY)))
        var size = CGSize(width: sizeX, height: sizeY)
        size = applyMinimumAreaRuleToSize(size)
        size = reCalulateSizeForBottomLeftAnchor(size)
        var center = cropRectComponent.bottomLeftAnchor_!.center
        center.x = (cropRectComponent.topRightAnchor_!.center.x - size.width)
        center.y = (cropRectComponent.topRightAnchor_!.center.y + size.height)
        cropRectComponent.bottomLeftAnchor_!.center = center
        recalculateCropRectFromTopRightAnchor()
        cropRectComponent.layoutViewsForCropRect()
    }
    
    fileprivate func reCalulateSizeForBottomLeftAnchor(_ size:CGSize) -> CGSize {
        var newSize = size
        if selectionMode != IMGLYSelectionMode.free {
            newSize.height = newSize.height * selectionRatio
            if (newSize.height > newSize.width) {
                newSize.width = newSize.height
            }
            newSize.height = newSize.width / selectionRatio
            
            if (cropRectComponent.topRightAnchor_!.center.x - newSize.width) < cropRectLeftBound {
                newSize.width = cropRectComponent.topRightAnchor_!.center.x - cropRectLeftBound
                newSize.height = newSize.width / selectionRatio
            }
            
            if (cropRectComponent.topRightAnchor_!.center.y + newSize.height) > cropRectBottomBound {
                newSize.height = cropRectBottomBound - cropRectComponent.topRightAnchor_!.center.y
                newSize.width = newSize.height * selectionRatio
            }
        }
        else {
            if (cropRectComponent.topRightAnchor_!.center.x - newSize.width) < cropRectLeftBound {
                newSize.width = cropRectComponent.topRightAnchor_!.center.x - cropRectLeftBound
            }
            if (cropRectComponent.topRightAnchor_!.center.y + newSize.height) > cropRectBottomBound {
                newSize.height = cropRectBottomBound - cropRectComponent.topRightAnchor_!.center.y
            }
        }
        return newSize
    }
    
    fileprivate func handlePanOnBottomRight(_ recognizer:UIPanGestureRecognizer) {
        let location = recognizer.location(in: transparentRectView)
        var sizeX = cropRectComponent.topLeftAnchor_!.center.x - location.x
        var sizeY = cropRectComponent.topLeftAnchor_!.center.y - location.y
        sizeX = CGFloat(abs(Int(sizeX)))
        sizeY = CGFloat(abs(Int(sizeY)))
        var size = CGSize(width: sizeX, height: sizeY)
        size = applyMinimumAreaRuleToSize(size)
        size = reCalulateSizeForBottomRightAnchor(size)
        var center = cropRectComponent.bottomRightAnchor_!.center
        center.x -= (cropRectComponent.cropRect.size.width - size.width)
        center.y -= (cropRectComponent.cropRect.size.height - size.height)
        cropRectComponent.bottomRightAnchor_!.center = center
        recalculateCropRectFromTopLeftAnchor()
        cropRectComponent.layoutViewsForCropRect()
    }
    
    fileprivate func reCalulateSizeForBottomRightAnchor(_ size:CGSize) -> CGSize {
        var newSize = size
        if selectionMode != IMGLYSelectionMode.free {
            newSize.height = newSize.height * selectionRatio
            if newSize.height > newSize.width {
                newSize.width = newSize.height
            }
            if (cropRectComponent.topLeftAnchor_!.center.x + newSize.width) > cropRectRightBound {
                newSize.width = cropRectRightBound - cropRectComponent.topLeftAnchor_!.center.x;
            }
            newSize.height = newSize.width / selectionRatio
            if (cropRectComponent.topLeftAnchor_!.center.y + newSize.height) > cropRectBottomBound {
                newSize.height = cropRectBottomBound - cropRectComponent.topLeftAnchor_!.center.y
                newSize.width = newSize.height * selectionRatio
            }
        }
        else {
            if (cropRectComponent.topLeftAnchor_!.center.x + newSize.width) > cropRectRightBound {
                newSize.width = cropRectRightBound - cropRectComponent.topLeftAnchor_!.center.x
            }
            if (cropRectComponent.topLeftAnchor_!.center.y + newSize.height) >  cropRectBottomBound {
                newSize.height =  cropRectBottomBound - cropRectComponent.topLeftAnchor_!.center.y
            }
        }
        return newSize
    }
    
    fileprivate func handlePanOnTransparentView(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: transparentRectView)
        if cropRectComponent.cropRect.contains(location) {
            calculateDragOffsetOnNewDrag(recognizer:recognizer)
            let newLocation = clampedLocationToBounds(location)
            var rect = cropRectComponent.cropRect
            rect.origin.x = newLocation.x - dragOffset.x
            rect.origin.y = newLocation.y - dragOffset.y
            cropRectComponent.cropRect = rect
            cropRectComponent.layoutViewsForCropRect()
        }
    }
    
    fileprivate func calculateDragOffsetOnNewDrag(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: transparentRectView)
        if recognizer.state == .began {
            dragOffset = CGPoint(x: location.x - cropRectComponent.cropRect.origin.x, y: location.y - cropRectComponent.cropRect.origin.y)
        }
    }
    
    fileprivate func clampedLocationToBounds(_ location: CGPoint) -> CGPoint {
        let rect = cropRectComponent.cropRect
        var locationX = location.x
        var locationY = location.y
        let left = locationX - dragOffset.x
        let right = left + rect.size.width
        let top  = locationY - dragOffset.y
        let bottom = top + rect.size.height
        
        if left < cropRectLeftBound {
            locationX = cropRectLeftBound + dragOffset.x
        }
        if right > cropRectRightBound {
            locationX = cropRectRightBound - cropRectComponent.cropRect.size.width  + dragOffset.x
        }
        if top < cropRectTopBound {
            locationY = cropRectTopBound + dragOffset.y
        }
        if bottom > cropRectBottomBound {
            locationY = cropRectBottomBound - cropRectComponent.cropRect.size.height + dragOffset.y
        }
        return CGPoint(x: locationX, y: locationY)
    }
    
    fileprivate func normalizedCropRect() -> CGRect {
        reCalculateCropRectBounds()
        let boundWidth = cropRectRightBound - cropRectLeftBound
        let boundHeight = cropRectBottomBound - cropRectTopBound
        let x = (cropRectComponent.cropRect.origin.x - cropRectLeftBound) / boundWidth
        let y = (cropRectComponent.cropRect.origin.y - cropRectTopBound) / boundHeight
        return CGRect(x: x, y: y, width: cropRectComponent.cropRect.size.width / boundWidth, height: cropRectComponent.cropRect.size.height / boundHeight)
    }
    
    fileprivate func reCalculateCropRectBounds() {
        let width = transparentRectView.frame.size.width
        let height = transparentRectView.frame.size.height
        cropRectLeftBound = (width - previewImageView.visibleImageFrame.size.width) / 2.0
        cropRectRightBound = width - cropRectLeftBound
        cropRectTopBound = (height - previewImageView.visibleImageFrame.size.height) / 2.0
        cropRectBottomBound = height - cropRectTopBound
    }
    
    fileprivate func applyMinimumAreaRuleToSize(_ size:CGSize) -> CGSize {
        var newSize = size
        if newSize.width < MinimumCropSize {
            newSize.width = MinimumCropSize
        }
        
        if newSize.height < MinimumCropSize {
            newSize.height = MinimumCropSize
        }
        return newSize
    }
    
    fileprivate func setInitialCropRect() {
        selectionRatio = 1.0
        setCropRectForSelectionRatio()
    }
    
    fileprivate func setCropRectForSelectionRatio() {
        let size = CGSize(width: cropRectRightBound - cropRectLeftBound,
            height: cropRectBottomBound - cropRectTopBound)
        var rectWidth = size.width
        var rectHeight = rectWidth
        if size.width > size.height {
            rectHeight = size.height
            rectWidth = rectHeight
        }
        rectHeight /= selectionRatio
        
        let sizeDeltaX = (size.width - rectWidth) / 2.0
        let sizeDeltaY = (size.height - rectHeight) / 2.0
        
        cropRectComponent.cropRect = CGRect(
            x: cropRectLeftBound  + sizeDeltaX,
            y: cropRectTopBound + sizeDeltaY,
            width: rectWidth,
            height: rectHeight)
    }
    
    fileprivate func calculateRatioForSelectionMode() {
        if selectionMode == IMGLYSelectionMode.fourToThree {
            selectionRatio = 4.0 / 3.0
        }
        else if selectionMode == IMGLYSelectionMode.oneToOne {
            selectionRatio = 1.0
        }
        else if selectionMode == IMGLYSelectionMode.sixteenToNine {
            selectionRatio = 16.0 / 9.0
        }
        if selectionMode != IMGLYSelectionMode.free {
            setCropRectForSelectionRatio()
            cropRectComponent.layoutViewsForCropRect()
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func activateFreeRatio(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectionMode = IMGLYSelectionMode.free
        calculateRatioForSelectionMode()
        
        selectedButton = sender
    }
    
    @objc fileprivate func activateOneToOneRatio(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectionMode = IMGLYSelectionMode.oneToOne
        calculateRatioForSelectionMode()
        
        selectedButton = sender
    }
    
    @objc fileprivate func activateFourToThreeRatio(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectionMode = IMGLYSelectionMode.fourToThree
        calculateRatioForSelectionMode()
        
        selectedButton = sender
    }
    
    @objc fileprivate func activateSixteenToNineRatio(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectionMode = IMGLYSelectionMode.sixteenToNine
        calculateRatioForSelectionMode()
        
        selectedButton = sender
    }
}

