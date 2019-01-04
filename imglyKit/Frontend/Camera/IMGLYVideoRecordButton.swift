//
//  IMGLYVideoRecordButton.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 26/06/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public final class IMGLYVideoRecordButton: UIControl {
    
    // MARK: - Properties
    
    static let lineWidth = CGFloat(2)
    static let recordingColor = UIColor(red:0.94, green:0.27, blue:0.25, alpha:1)
    public var recording = false {
        didSet {
            updateInnerLayer()
        }
    }
    
    fileprivate lazy var outerLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = IMGLYVideoRecordButton.lineWidth
        layer.fillColor = UIColor.clear.cgColor
        return layer
        }()
    
    fileprivate lazy var innerLayer: IMGLYShapeLayer = {
        let layer = IMGLYShapeLayer()
        layer.fillColor = IMGLYVideoRecordButton.recordingColor.cgColor
        return layer
        }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(outerLayer)
        layer.addSublayer(innerLayer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.addSublayer(outerLayer)
        layer.addSublayer(innerLayer)
    }
    
    // MARK: - Helpers
    
    fileprivate func updateOuterLayer() {
        let outerRect = bounds.insetBy(dx: IMGLYVideoRecordButton.lineWidth, dy: IMGLYVideoRecordButton.lineWidth)
        outerLayer.frame = bounds
        outerLayer.path = UIBezierPath(ovalIn: outerRect).cgPath
    }
    
    fileprivate func updateInnerLayer() {
        if recording {
            let innerRect = bounds.insetBy(dx: 0.3 * bounds.size.width, dy: 0.3 * bounds.size.height)
            innerLayer.frame = bounds
            innerLayer.path = UIBezierPath(roundedRect: innerRect, cornerRadius: 4).cgPath
        } else {
            let innerRect = bounds.insetBy(dx: IMGLYVideoRecordButton.lineWidth * 2.5, dy: IMGLYVideoRecordButton.lineWidth * 2.5)
            innerLayer.frame = bounds
            innerLayer.path = UIBezierPath(roundedRect: innerRect, cornerRadius: innerRect.size.width / 2).cgPath
        }
    }
    
    // MARK: - UIView
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateOuterLayer()
        updateInnerLayer()
    }
    
    // MARK: - UIControl
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if !innerLayer.contains(location) {
            return false
        }
        
        innerLayer.fillColor = IMGLYVideoRecordButton.recordingColor.withAlphaComponent(0.3).cgColor
        return true
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        recording = !recording
        innerLayer.fillColor = IMGLYVideoRecordButton.recordingColor.cgColor
        sendActions(for: .touchUpInside)
    }
    
    public override func cancelTracking(with event: UIEvent?) {
        innerLayer.fillColor = IMGLYVideoRecordButton.recordingColor.cgColor
    }
}
