//
//  IMGLYImageCaptionCollectionViewCell.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 08/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

class IMGLYImageCaptionCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
        }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor(white: 0.5, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        configureViews()
    }
    
    // MARK: - Helpers
    
    fileprivate func configureViews() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        containerView.addSubview(textLabel)
        
        contentView.addSubview(containerView)
        
        let views = [
            "containerView" : containerView,
            "imageView" : imageView,
            "textLabel" : textLabel
        ]
        
        let metrics: [ String: AnyObject ] = [
            "imageHeight" : imageSize.height as AnyObject,
            "imageWidth" : imageSize.width as AnyObject,
            "imageCaptionMargin" : imageCaptionMargin as AnyObject
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
        
        contentView.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    // MARK: - Subclasses
    
    var imageSize: CGSize {
        // Subclasses should override this
        return CGSize.zero
    }
    
    var imageCaptionMargin: CGFloat {
        // Subclasses should override this
        return 0
    }
    
}
