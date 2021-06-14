//
//  IMGLYStickersEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 10/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import Gifu
import AVFoundation

let StickersCollectionViewCellSize = CGSize(width: 90, height: 90)
let StickersCollectionViewCellReuseIdentifier = "StickersCollectionViewCell"

open class IMGLYStickersEditorViewController: IMGLYSubEditorViewController {

    // MARK: - Properties
    private let ButtonCollectionViewCellReuseIdentifier = "ButtonCollectionViewCell"
    private let ButtonCollectionViewCellSize = CGSize(width: 66, height: 90)
    open var stickersDataSource = IMGLYStickersDataSource()
    var binView = UIView()
    var binZone: CGRect?
    var rotated: CGFloat = 0
    let impact = UIImpactFeedbackGenerator()
    let StickersCollectionViewTag = 99
    var binCenter: CGPoint? {
        if let binZone = binZone {
            return CGPoint(x: binZone.origin.x + binZone.width/2, y: binZone.origin.y + binZone.height/2)
        }
        return nil
    }
    
    var currentSize: CGSize?
    var distanceFromTouch: CGSize?
    
    open fileprivate(set) lazy var stickersClipView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
        }()
    
    open fileprivate(set) lazy var stickerSelectorContainerView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentView.layer.borderColor = UIColor.white.cgColor
        view.contentView.layer.borderWidth = 1.5
        return view
    }()
    
    open fileprivate(set) lazy var titleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 36.0/255, green: 36.0/255, blue: 36.0/255, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        let views: [String : AnyObject] = ["titleLabel" : titleLabel,
                                           "closeButton" : closeButton]
        let metrics: [String : AnyObject] = [
            "btnHeight" : 35 as AnyObject
        ]
       
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[titleLabel]-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel]-|", options: [], metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[closeButton(==btnHeight)]-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[closeButton]-|", options: [], metrics: metrics, views: views))
        return view
    }()
    
    open fileprivate(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        let bundle = Bundle(for: type(of: self))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.text = NSLocalizedString("stickers-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        return label
        }()
    
    open fileprivate(set) lazy var closeButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(IMGLYStickersEditorViewController.closeBtn(_:)), for: .touchUpInside)
        return button
        }()
 
    
    fileprivate var draggedView: UIView?
    fileprivate var tempStickerCopy = [CIFilter]()
    
    open lazy var actionButtons: [IMGLYActionButton] = {
        let bundle = Bundle(for: type(of: self))
        var handlers = [IMGLYActionButton]()
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.magic", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_magic", in: bundle, compatibleWith: nil),
                selectedImage: UIImage(named: "icon_option_magic_active", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.magic) },
                showSelection: { [unowned self] in return self.fixedFilterStack.enhancementFilter._enabled }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.text", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_text", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.text) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.stickers", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_sticker", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.stickers) }, isEnabled: true))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.filter", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_filters", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.filter) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.crop", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_crop", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.crop) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.orientation", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_orientation", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.orientation) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.brightness", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_brightness", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.brightness) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.contrast", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_contrast", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.contrast) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.saturation", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_saturation", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.saturation) }, isEnabled: false))
        
        handlers.append(
            IMGLYActionButton(
                title: NSLocalizedString("main-editor.button.focus", tableName: nil, bundle: bundle, value: "", comment: ""),
                image: UIImage(named: "icon_option_focus", in: bundle, compatibleWith: nil),
                handler: { [unowned self] in self.subEditorButtonPressed(.focus) }, isEnabled: false))
        
        return handlers
    }()
    
    fileprivate func subEditorButtonPressed(_ buttonType: IMGLYMainMenuButtonType) {
        UIView.transition(with: self.stickerSelectorContainerView, duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.stickerSelectorContainerView.isHidden = false
                            self.bottomContainerView.isHidden = true
                          })
    }
    
    
    // MARK: - SubEditorViewController
    
    open override func tappedDone(_ sender: UIBarButtonItem?) {
        var addedStickers = false
        var containsGif: Bool = false

        for view in stickersClipView.subviews {
            if let view = view as? IMGLYGIFImageView {
                if let image = view.image {
                    let stickerFilter = IMGLYInstanceFactory.stickerFilter()
                    let sticker = view.sticker
                    sticker?.resultImage = image
                    stickerFilter.sticker = sticker
                    let center = CGPoint(x: view.center.x / stickersClipView.frame.size.width,
                                         y: view.center.y / stickersClipView.frame.size.height)
                    
                    var size = initialSizeForStickerImage(image)
                    size.width = size.width / stickersClipView.bounds.size.width
                    size.height = size.height / stickersClipView.bounds.size.height
                    stickerFilter.center = center
                    stickerFilter.scale = size.width
                    stickerFilter.transform = view.transform
                    fixedFilterStack.stickerFilters.append(stickerFilter)
                    addedStickers = true
                }
                if view.isAnimatingGIF {
                    containsGif = true
                }
            }
        }
        IMGLYStrickersManager.shared.addedGifStickers = containsGif
        if addedStickers {
            updatePreviewImageWithCompletion {
                self.stickersClipView.removeFromSuperview()
                IMGLYStrickersManager.shared.stickersClipView = self.stickersClipView
                super.tappedDone(sender)
            }
        } else {
            super.tappedDone(sender)
        }
    }
    
    // MARK: - Helpers
    
    fileprivate func initialSizeForStickerImage(_ image: UIImage) -> CGSize {
        let initialMaxStickerSize = stickersClipView.bounds.width * 0.3
        let widthRatio = initialMaxStickerSize / image.size.width
        let heightRatio = initialMaxStickerSize / image.size.height
        let scale = min(widthRatio, heightRatio)
        
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }
    
    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("stickers-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        configureStickersClipView()
        configureGestureRecognizers()
        configureStickersCollectionView()
        backupStickers()
        fixedFilterStack.stickerFilters.removeAll()
        setupBinView()
        configureMenuCollectionView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rerenderPreviewWithoutStickers()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        stickersClipView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
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
        bottomContainerView.isHidden = true
    }
    
    fileprivate func configureStickersCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = StickersCollectionViewCellSize
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.tag = StickersCollectionViewTag
        collectionView.dataSource = stickersDataSource
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.register(IMGLYStickerCollectionViewCell.self, forCellWithReuseIdentifier: StickersCollectionViewCellReuseIdentifier)
        view.addSubview(stickerSelectorContainerView)
        navigationItem.rightBarButtonItem?.isEnabled = false
        stickerSelectorContainerView.contentView.addSubview(collectionView)
        stickerSelectorContainerView.contentView.addSubview(titleContainerView)
        
        let views: [String : AnyObject] = ["collectionView" : collectionView,
                                           "stickerSelectorContainerView" : stickerSelectorContainerView,
                                           "titleContainerView" : titleContainerView]
        
        let metrics: [String : AnyObject] = [
            "margin" : 40 as AnyObject,
            "titleHeight" : 35 as AnyObject,
        ]
        
        stickerSelectorContainerView.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[collectionView]|", options: [], metrics: metrics, views: views))
        stickerSelectorContainerView.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[titleContainerView]|", options: [], metrics: metrics, views: views))
        stickerSelectorContainerView.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[titleContainerView(==titleHeight)]-[collectionView]|", options: [], metrics: metrics, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(==margin)-[stickerSelectorContainerView]-(==margin)-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==margin)-[stickerSelectorContainerView]-(==margin)-|", options: [], metrics: metrics, views: views))
    }
    
    fileprivate func configureStickersClipView() {
        view.addSubview(stickersClipView)
    }
    
    fileprivate func configureGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(IMGLYStickersEditorViewController.panned(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        stickersClipView.addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(IMGLYStickersEditorViewController.pinched(_:)))
        pinchGestureRecognizer.delegate = self
        stickersClipView.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(IMGLYStickersEditorViewController.rotated(_:)))
        rotationGestureRecognizer.delegate = self
        stickersClipView.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    // MARK: - Gesture Handling
    
    @objc fileprivate func panned(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: stickersClipView)
        let translation = recognizer.translation(in: stickersClipView)
        
        switch recognizer.state {
        case .began:
            self.binZone = binView.frame
            draggedView = stickersClipView.hitTest(location, with: nil) as? UIImageView
            if let draggedView = draggedView {
                stickersClipView.bringSubviewToFront(draggedView)
                self.isMoving()
            }
        case .changed:
            if let draggedView = draggedView {
                draggedView.center = CGPoint(x: draggedView.center.x + translation.x, y: draggedView.center.y + translation.y)
            }
            
            recognizer.setTranslation(CGPoint.zero, in: stickersClipView)
            let touch = recognizer.location(ofTouch: 0, in: stickersClipView)
            
            if let binZone = binZone, isInBinZone(touch) {
                animateInBin(binZone: binZone, touch: touch)
            } else {
                animateOutBinFrom(touch: touch)
            }
            
        case .cancelled, .ended:
            if isInBinZone(self.draggedView?.center) {
                removeStickers()
            }
            self.isStopping()
            draggedView = nil
        default:
            break
        }
    }

    func setupBinView() {
       
        let imageView = UIImageView(image: UIImage(systemName: "trash"))
        
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        binView.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: binView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: binView.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 25).isActive = true

        binView.translatesAutoresizingMaskIntoConstraints = false
        self.stickersClipView.addSubview(binView)
        binView.centerXAnchor.constraint(equalTo: self.stickersClipView.centerXAnchor).isActive = true
        binView.bottomAnchor.constraint(equalTo: self.stickersClipView.bottomAnchor, constant: -2.5).isActive = true
        binView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        binView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        binView.layer.cornerRadius = 25
        binView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
        binView.isHidden = true
    }
    
    func isMoving() {
        binView.isHidden = false
        self.stickersClipView.bringSubviewToFront(binView)
    }
    
    func isStopping() {
        binView.isHidden = true
    }
    
    func animateInBin(binZone: CGRect, touch: CGPoint) {
        if currentSize == nil {
            //Rotate first
            let zKeyPath = "layer.presentationLayer.transform.rotation.z"
            let imageRotation = (self.draggedView?.value(forKeyPath: zKeyPath) as? NSNumber)?.floatValue ?? 0.0
            self.rotated = CGFloat(imageRotation)
            self.draggedView?.transform = self.draggedView?.transform.rotated(by: -self.rotated) ?? .identity
            currentSize = self.draggedView?.frame.size
            distanceFromTouch = CGSize(width: touch.x-(self.draggedView?.frame.origin.x ?? 0), height: touch.y-(self.draggedView?.frame.origin.y ?? 0))
            impact.impactOccurred()
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.draggedView?.frame.size.width = 30
            self.draggedView?.frame.size.height = 30
            self.draggedView?.center = self.binCenter!
        })
    }
    
    func animateOutBinFrom(touch: CGPoint) {
        
        if let currentSize = self.currentSize, let distanceFromTouch = self.distanceFromTouch {
            UIView.animate(withDuration: 0.2, animations: {
                self.draggedView?.frame.origin = CGPoint(x: touch.x-distanceFromTouch.width, y: touch.y-distanceFromTouch.height)
                self.draggedView?.frame.size.width = currentSize.width
                self.draggedView?.frame.size.height = currentSize.height
                self.draggedView?.transform = self.draggedView?.transform.rotated(by: self.rotated) ?? .identity
                
            })
            self.currentSize = nil
            self.distanceFromTouch = nil
            self.rotated = 0
        }
    }
    
    func isInBinZone(_ touch: CGPoint?) -> Bool {
        guard let binCenter = binCenter,
              let touch = touch else { return false }
        if touch.x > binCenter.x - 40 && touch.x < binCenter.x + 40 && touch.y > binCenter.y - 40 && touch.y < binCenter.y + 40 {
            return true
        }
        return false
    }
    
    fileprivate func removeStickers() {
        if let draggedView = draggedView as? IMGLYGIFImageView {
            draggedView.removeFromSuperview()
            self.updateAddedGifStickers()
        }
    }
    
    fileprivate func updateAddedGifStickers() {
        var containsGif = false
        for view in stickersClipView.subviews {
            if  let view = view as? IMGLYGIFImageView,
                view.isAnimatingGIF {
                containsGif = true
            }
            
        }
        IMGLYStrickersManager.shared.addedGifStickers = containsGif
    }
   
    
    @objc fileprivate func pinched(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.numberOfTouches == 2 {
            let point1 = recognizer.location(ofTouch: 0, in: stickersClipView)
            let point2 = recognizer.location(ofTouch: 1, in: stickersClipView)
            let midpoint = CGPoint(x:(point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            let scale = recognizer.scale
            
            switch recognizer.state {
            case .began:
                if draggedView == nil {
                    draggedView = stickersClipView.hitTest(midpoint, with: nil) as? UIImageView
                }
                
                if let draggedView = draggedView {
                    stickersClipView.bringSubviewToFront(draggedView)
                }
            case .changed:
                if let draggedView = draggedView {
                    draggedView.transform = draggedView.transform.scaledBy(x: scale, y: scale)
                }
                
                recognizer.scale = 1
            case .cancelled, .ended:
                draggedView = nil
            default:
                break
            }
        }
    }
    
    @objc fileprivate func rotated(_ recognizer: UIRotationGestureRecognizer) {
        if recognizer.numberOfTouches == 2 {
            let point1 = recognizer.location(ofTouch: 0, in: stickersClipView)
            let point2 = recognizer.location(ofTouch: 1, in: stickersClipView)
            let midpoint = CGPoint(x:(point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            let rotation = recognizer.rotation
            
            switch recognizer.state {
            case .began:
                if draggedView == nil {
                    draggedView = stickersClipView.hitTest(midpoint, with: nil) as? UIImageView
                }
                
                if let draggedView = draggedView {
                    stickersClipView.bringSubviewToFront(draggedView)
                }
            case .changed:
                if let draggedView = draggedView {
                    draggedView.transform = draggedView.transform.rotated(by: rotation)
                }
                
                recognizer.rotation = 0
            case .cancelled, .ended:
                draggedView = nil
            default:
                break
            }
        }
    }
    
    @objc open func closeBtn(_ sender: UIButton?) {
        UIView.transition(with: self.bottomContainerView, duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.stickerSelectorContainerView.isHidden = true
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                            self.bottomContainerView.isHidden = false
                          })

    }
    
    // MARK: - sticker object restore
    
    fileprivate func rerenderPreviewWithoutStickers() {
        updatePreviewImageWithCompletion { () -> (Void) in
            self.addStickerImagesFromStickerFilters(self.tempStickerCopy)
        }
    }
    
    fileprivate func addStickerImagesFromStickerFilters(_ stickerFilters: [CIFilter]) {
        for element in stickerFilters {
            guard let stickerFilter = element as? IMGLYStickerFilter, let sticker = stickerFilter.sticker, let imageView = createImageView(sticker: sticker) else {
                return
            }
            imageView.isUserInteractionEnabled = true
            
            let size = stickerFilter.absolutStickerSizeForImageSize(stickersClipView.bounds.size)
            imageView.frame.size = size
            
            let center = CGPoint(x: stickerFilter.center.x * stickersClipView.frame.size.width,
                                 y: stickerFilter.center.y * stickersClipView.frame.size.height)
            imageView.center = center
            imageView.transform = stickerFilter.transform
            stickersClipView.addSubview(imageView)
        }
    }
    
    fileprivate func backupStickers() {
        tempStickerCopy = fixedFilterStack.stickerFilters
    }
}

extension IMGLYStickersEditorViewController: UICollectionViewDelegate {
    // add selected sticker
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == StickersCollectionViewTag {
            let sticker = stickersDataSource.stickers[indexPath.row]
            
            if let imageView = createImageView(sticker: sticker) {
                imageView.frame.size = initialSizeForStickerImage(imageView.image ?? UIImage())
                imageView.isUserInteractionEnabled = true
                imageView.center = CGPoint(x: stickersClipView.bounds.midX, y: stickersClipView.bounds.midY)
                stickersClipView.addSubview(imageView)
                imageView.transform = CGAffineTransform(scaleX: 0, y: 0)
                UIView.transition(with: self.bottomContainerView, duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.stickerSelectorContainerView.isHidden = true
                                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                                    self.bottomContainerView.isHidden = false
                                  })
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                    imageView.transform = CGAffineTransform.identity
                    }, completion: nil)
            } else {
                let bundle = Bundle(for: type(of: self))
                let alertController = UIAlertController(title: nil, message:  NSLocalizedString("main-editor.stickers.not.authorized", tableName: nil, bundle: bundle, value: "", comment: ""), preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
        } else {
            let actionButton = actionButtons[indexPath.item]
            if actionButton.isEnabled ?? false {
                actionButton.handler()
            }
        }
    }
    
    private func createImageView(sticker: IMGLYSticker) -> IMGLYGIFImageView? {
        if let image = sticker.image {
            let imageView = IMGLYGIFImageView(image: image)
            imageView.sticker = sticker
            return imageView
        } else if let dataGif = sticker.dataGif,
                  IMGLYStrickersManager.shared.canAddGifStickers{
            let imageView = IMGLYGIFImageView()
            imageView.prepareForAnimation(withGIFData: dataGif)
            imageView.startAnimatingGIF()
            imageView.sticker = sticker
            return imageView
        }
        return  nil
    }
}

extension IMGLYStickersEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) || (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
            return true
        }
        
        return false
    }
}

extension IMGLYStickersEditorViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actionButtons.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ButtonCollectionViewCellReuseIdentifier, for: indexPath)
        
        if let buttonCell = cell as? IMGLYButtonCollectionViewCell {
            let actionButton = actionButtons[indexPath.item]
            
            if let selectedImage = actionButton.selectedImage, let showSelectionBlock = actionButton.showSelection, showSelectionBlock() {
                buttonCell.imageView.image = selectedImage.withRenderingMode(.alwaysTemplate)
            } else {
                buttonCell.imageView.image = actionButton.image?.withRenderingMode(.alwaysTemplate)
            }
            
            buttonCell.textLabel.text = actionButton.title
            if !(actionButton.isEnabled ?? false) {
                buttonCell.imageView.tintColor = UIColor(red: 198.0/255, green: 198.0/255, blue: 198.0/255, alpha: 0.25)
                buttonCell.textLabel.textColor = buttonCell.imageView.tintColor
            } else {
                buttonCell.imageView.tintColor = .white
            }
            
        }
        
        return cell
    }
    
   
}
