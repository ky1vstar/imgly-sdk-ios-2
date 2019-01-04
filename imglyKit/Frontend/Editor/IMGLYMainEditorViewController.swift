//
//  IMGLYMainEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 07/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

@objc public enum IMGLYEditorResult: Int {
    case done
    case cancel
}

@objc public enum IMGLYMainMenuButtonType: Int {
    case magic
    case filter
    case stickers
    case orientation
    case focus
    case crop
    case brightness
    case contrast
    case saturation
    case noise
    case text
    case reset
}

public typealias IMGLYEditorCompletionBlock = (IMGLYEditorResult, UIImage?) -> Void

private let ButtonCollectionViewCellReuseIdentifier = "ButtonCollectionViewCell"
private let ButtonCollectionViewCellSize = CGSize(width: 66, height: 90)

open class IMGLYMainEditorViewController: IMGLYEditorViewController {
    
    // MARK: - Properties
    
    open lazy var actionButtons: [IMGLYActionButton] = {
        let bundle = Bundle(for: type(of: self))
        var handlers = [IMGLYActionButton]()
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.magic", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_magic", in: bundle, compatibleWith: nil),
                selectedImage: UIImage(named: "icon_option_magic_active", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.magic) },
                showSelection: { [unowned self] in return self.fixedFilterStack.enhancementFilter._enabled }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.filter", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_filters", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.filter) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.stickers", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_sticker", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.stickers) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.orientation", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_orientation", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.orientation) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.focus", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_focus", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.focus) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.crop", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_crop", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.crop) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.brightness", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_brightness", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.brightness) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.contrast", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_contrast", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.contrast) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.saturation", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_saturation", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.saturation) }))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.text", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_text", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.text) }))
        
        return handlers
        }()
    
    open var completionBlock: IMGLYEditorCompletionBlock?
    open var initialFilterType = IMGLYFilterType.none
    open var initialFilterIntensity = NSNumber(value: 0.75 as Double)
    open fileprivate(set) var fixedFilterStack = IMGLYFixedFilterStack()
    
    fileprivate let maxLowResolutionSideLength = CGFloat(1600)
    open var highResolutionImage: UIImage? {
        didSet {
            generateLowResolutionImage()
        }
    }
    
    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("main-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(IMGLYMainEditorViewController.cancelTapped(_:)))
        
        navigationController?.delegate = self
        
        fixedFilterStack.effectFilter = IMGLYInstanceFactory.effectFilterWithType(initialFilterType)
        fixedFilterStack.effectFilter.inputIntensity = initialFilterIntensity
        
        updatePreviewImage()
        configureMenuCollectionView()
    }
    
    // MARK: - Configuration
    
    fileprivate func configureMenuCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = ButtonCollectionViewCellSize
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(IMGLYButtonCollectionViewCell.self, forCellWithReuseIdentifier: ButtonCollectionViewCellReuseIdentifier)
        
        let views = [ "collectionView" : collectionView ]
        bottomContainerView.addSubview(collectionView)
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[collectionView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: [], metrics: nil, views: views))
    }
    
    // MARK: - Helpers
    
    fileprivate func subEditorButtonPressed(_ buttonType: IMGLYMainMenuButtonType) {
        if (buttonType == IMGLYMainMenuButtonType.magic) {
            if !updating {
                fixedFilterStack.enhancementFilter._enabled = !fixedFilterStack.enhancementFilter._enabled
                updatePreviewImage()
            }
        } else {
            if let viewController = IMGLYInstanceFactory.viewControllerForButtonType(buttonType, withFixedFilterStack: fixedFilterStack) {
                viewController.lowResolutionImage = lowResolutionImage
                viewController.previewImageView.image = previewImageView.image
                viewController.completionHandler = subEditorDidComplete
                
                show(viewController, sender: self)
            }
        }
    }
    
    fileprivate func subEditorDidComplete(_ image: UIImage?, fixedFilterStack: IMGLYFixedFilterStack) {
        previewImageView.image = image
        self.fixedFilterStack = fixedFilterStack
    }
    
    fileprivate func generateLowResolutionImage() {
        if let highResolutionImage = self.highResolutionImage {
            if highResolutionImage.size.width > maxLowResolutionSideLength || highResolutionImage.size.height > maxLowResolutionSideLength  {
                let scale: CGFloat
                
                if(highResolutionImage.size.width > highResolutionImage.size.height) {
                    scale = maxLowResolutionSideLength / highResolutionImage.size.width
                } else {
                    scale = maxLowResolutionSideLength / highResolutionImage.size.height
                }
                
                let newWidth  = CGFloat(roundf(Float(highResolutionImage.size.width) * Float(scale)))
                let newHeight = CGFloat(roundf(Float(highResolutionImage.size.height) * Float(scale)))
                lowResolutionImage = highResolutionImage.imgly_normalizedImageOfSize(CGSize(width: newWidth, height: newHeight))
            } else {
                lowResolutionImage = highResolutionImage.imgly_normalizedImage
            }
        }
    }
    
    fileprivate func updatePreviewImage() {
        if let lowResolutionImage = self.lowResolutionImage {
            updating = true
            PhotoProcessorQueue.async {
                let processedImage = IMGLYPhotoProcessor.processWithUIImage(lowResolutionImage, filters: self.fixedFilterStack.activeFilters)
                
                DispatchQueue.main.async {
                    self.previewImageView.image = processedImage
                    self.updating = false
                }
            }
        }
    }
    
    // MARK: - EditorViewController
    
    override open func tappedDone(_ sender: UIBarButtonItem?) {
        if let completionBlock = completionBlock {
            highResolutionImage = highResolutionImage?.imgly_normalizedImage
            var filteredHighResolutionImage: UIImage?
            
            if let highResolutionImage = self.highResolutionImage {
                sender?.isEnabled = false
                PhotoProcessorQueue.async {
                    filteredHighResolutionImage = IMGLYPhotoProcessor.processWithUIImage(highResolutionImage, filters: self.fixedFilterStack.activeFilters)
                    
                    DispatchQueue.main.async {
                        completionBlock(.done, filteredHighResolutionImage)
                        sender?.isEnabled = true
                    }
                }
            } else {
                completionBlock(.done, filteredHighResolutionImage)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func cancelTapped(_ sender: UIBarButtonItem?) {
        if let completionBlock = completionBlock {
            completionBlock(.cancel, nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    open override var enableZoomingInPreviewImage: Bool {
        return true
    }
}

extension IMGLYMainEditorViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actionButtons.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ButtonCollectionViewCellReuseIdentifier, for: indexPath) 
        
        if let buttonCell = cell as? IMGLYButtonCollectionViewCell {
            let actionButton = actionButtons[indexPath.item]
            
            if let selectedImage = actionButton.selectedImage, let showSelectionBlock = actionButton.showSelection, showSelectionBlock() {
                buttonCell.imageView.image = selectedImage
            } else {
                buttonCell.imageView.image = actionButton.image
            }
            
            buttonCell.textLabel.text = actionButton.title
        }
        
        return cell
    }
}

extension IMGLYMainEditorViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let actionButton = actionButtons[indexPath.item]
        actionButton.handler()
        
        if actionButton.selectedImage != nil && actionButton.showSelection != nil {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

extension IMGLYMainEditorViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return IMGLYNavigationAnimationController()
    }
}
