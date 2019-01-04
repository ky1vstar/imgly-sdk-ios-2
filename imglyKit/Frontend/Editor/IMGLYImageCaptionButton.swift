//
//  IMGLYImageCaptionButton.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

private let ImageSize = CGSize(width: 36, height: 36)
private let ImageCaptionMargin = 2

open class IMGLYImageCaptionButton: UIControl {
    
    // MARK: - Properties
    
    open fileprivate(set) lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.white
        return label
        }()
    
    open fileprivate(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
        }()
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UIColor(white: 1, alpha: 0.2)
            } else if !isSelected {
                backgroundColor = UIColor.clear
            }
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = UIColor(white: 1, alpha: 0.2)
            } else if !isHighlighted {
                backgroundColor = UIColor.clear
            }
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        backgroundColor = UIColor.clear
        configureViews()
    }
    
    // MARK: - Configuration
    
    fileprivate func configureViews() {
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        containerView.addSubview(textLabel)
        addSubview(containerView)
        
        let views = [
            "containerView" : containerView,
            "imageView" : imageView,
            "textLabel" : textLabel
        ]
        
        let metrics: [ String: AnyObject ] = [
            "imageHeight" : ImageSize.height as AnyObject,
            "imageWidth" : ImageSize.width as AnyObject,
            "imageCaptionMargin" : ImageCaptionMargin as AnyObject
        ]
        
        containerView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "|-(>=0)-[imageView(==imageWidth)]-(>=0)-|",
            options: [],
            metrics: metrics,
            views: views))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "|-(>=0)-[textLabel]-(>=0)-|",
            options: [],
            metrics: metrics,
            views: views))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[imageView(==imageHeight)]-(imageCaptionMargin)-[textLabel]|",
            options: .alignAllCenterX,
            metrics: metrics,
            views: views))
        
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    // MARK: - UIView
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return systemLayoutSizeFitting(size)
    }
    
    open override class var requiresConstraintBasedLayout : Bool {
        return true
    }

}
