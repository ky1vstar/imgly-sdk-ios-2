//
//  IMGLYZoomingImageView.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/05/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYZoomingImageView: UIScrollView {
    
    // MARK: - Properties
    
    open var image: UIImage? {
        get {
            return imageView.image
        }
        
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            contentSize = imageView.frame.size
            initialZoomScaleWasSet = false
            setNeedsLayout()
        }
    }
    
    fileprivate let imageView = UIImageView()
    fileprivate var initialZoomScaleWasSet = false
    open lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(IMGLYZoomingImageView.doubleTapped(_:)))
        gestureRecognizer.numberOfTapsRequired = 2
        return gestureRecognizer
        }()
    
    open var visibleImageFrame: CGRect {
        var visibleImageFrame = bounds
        visibleImageFrame = visibleImageFrame.intersection(imageView.frame)
        return visibleImageFrame
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: CGRect())
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        addSubview(imageView)
        addGestureRecognizer(doubleTapGestureRecognizer)
        
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        maximumZoomScale = 2
        scrollsToTop = false
        decelerationRate = .fast
        isExclusiveTouch = true
        delegate = self
    }
    
    // MARK: - UIView
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if imageView.image != nil {
            if !initialZoomScaleWasSet {
                minimumZoomScale = min(frame.size.width / imageView.bounds.size.width, frame.size.height / imageView.bounds.size.height)
                zoomScale = minimumZoomScale
                initialZoomScaleWasSet = true
            }
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func doubleTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: imageView)
        
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            zoom(to: CGRect(x: location.x, y: location.y, width: 1, height: 1), animated: true)
        }
    }
}

extension IMGLYZoomingImageView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((bounds.size.width - contentSize.width) * 0.5, 0)
        let offsetY = max((bounds.size.height - contentSize.height) * 0.5, 0)
        
        imageView.center = CGPoint(x: contentSize.width * 0.5 + offsetX, y: contentSize.height * 0.5 + offsetY)
    }
}
