//
// Created by Carsten Przyluczky on 01/03/15.
// Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYCircleGradientView : UIView {
    open var centerPoint = CGPoint.zero
    open weak var gradientViewDelegate: IMGLYGradientViewDelegate?
    open var controllPoint1 = CGPoint.zero
    fileprivate var controllPoint2_ = CGPoint.zero
    open var controllPoint2:CGPoint {
        get {
            return controllPoint2_
        }
        set (point) {
            controllPoint2_ = point
            calculateCenterPointFromOtherControlPoints()
            layoutCrosshair()
            setNeedsDisplay()
            if gradientViewDelegate != nil {
                gradientViewDelegate!.controlPointChanged()
            }
        }
    }
    
    open var normalizedControlPoint1:CGPoint {
        get {
            return CGPoint(x: controllPoint1.x / frame.size.width, y: controllPoint1.y / frame.size.height)
        }
    }

    open var normalizedControlPoint2:CGPoint {
        get {
            return CGPoint(x: controllPoint2.x / frame.size.width, y: controllPoint2.y / frame.size.height)
        }
    }

    fileprivate var crossImageView_ = UIImageView()
    fileprivate var setup = false
    
    public override init(frame:CGRect) {
        super.init(frame:frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    open func commonInit() {
        if setup {
            return
        }
        setup = true
        
        backgroundColor = UIColor.clear
        configureControlPoints()
        configureCrossImageView()
        configurePanGestureRecognizer()
        configurePinchGestureRecognizer()
    }
    
    open func configureControlPoints() {
        controllPoint1 = CGPoint(x: 100,y: 100);
        controllPoint2 = CGPoint(x: 150,y: 200);
        calculateCenterPointFromOtherControlPoints()
    }
    
    open func configureCrossImageView() {
        crossImageView_.image = UIImage(named: "crosshair", in: Bundle(for: type(of: self)), compatibleWith:nil)
        crossImageView_.isUserInteractionEnabled = true
        crossImageView_.frame = CGRect(x: 0, y: 0, width: crossImageView_.image!.size.width, height: crossImageView_.image!.size.height)
        addSubview(crossImageView_)
    }
    
    open func configurePanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:#selector(IMGLYCircleGradientView.handlePanGesture(_:)))
        addGestureRecognizer(panGestureRecognizer)
        crossImageView_.addGestureRecognizer(panGestureRecognizer)
    }
    
    open func configurePinchGestureRecognizer() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target:self, action:#selector(IMGLYCircleGradientView.handlePinchGesture(_:)))
        addGestureRecognizer(pinchGestureRecognizer)
    }
    
    open func diagonalLengthOfFrame() -> CGFloat {
        return sqrt(frame.size.width * frame.size.width +
            frame.size.height * frame.size.height)
    }
    
    open override func draw(_ rect:CGRect) {
        let aPath = UIBezierPath(arcCenter: centerPoint, radius: distanceBetweenControlPoints() * 0.5, startAngle: 0,
            endAngle: CGFloat.pi * 2, clockwise: true)
        UIColor(white: 0.8, alpha: 1.0).setStroke()
        aPath.close()
        
        let aRef = UIGraphicsGetCurrentContext()
        aRef?.saveGState()
        aPath.lineWidth = 1
        aPath.stroke()
        aRef?.restoreGState()
    }
    
    open func distanceBetweenControlPoints() -> CGFloat {
        let diffX = controllPoint2.x - controllPoint1.x
        let diffY = controllPoint2.y - controllPoint1.y
        
        return sqrt(diffX * diffX + diffY  * diffY)
    }
    
    open func calculateCenterPointFromOtherControlPoints() {
        centerPoint = CGPoint(x: (controllPoint1.x + controllPoint2.x) / 2.0,
            y: (controllPoint1.y + controllPoint2.y) / 2.0)
    }
    
    open func informDeletageAboutRecognizerStates(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            if gradientViewDelegate != nil {
                gradientViewDelegate!.userInteractionStarted()
            }
        }
        if recognizer.state == .ended {
            if gradientViewDelegate != nil {
                gradientViewDelegate!.userInteractionEnded()
            }
        }
    }
    
    @objc open func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        informDeletageAboutRecognizerStates(recognizer: recognizer)
        let diffX = location.x - centerPoint.x
        let diffY = location.y - centerPoint.y
        controllPoint1 = CGPoint(x: controllPoint1.x + diffX, y: controllPoint1.y + diffY)
        controllPoint2 = CGPoint(x: controllPoint2.x + diffX, y: controllPoint2.y + diffY)
    }
    
    @objc open func handlePinchGesture(_ recognizer:UIPinchGestureRecognizer) {
        informDeletageAboutRecognizerStates(recognizer: recognizer)
        if recognizer.numberOfTouches > 1 {
            controllPoint1 = recognizer.location(ofTouch: 0, in:self)
            controllPoint2 = recognizer.location(ofTouch: 1, in:self)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutCrosshair()
        setNeedsDisplay()
    }
    
    open func layoutCrosshair() {
        crossImageView_.center = centerPoint
    }
    
    open func centerGUIElements() {
        let x1 = frame.size.width * 0.25
        let x2 = frame.size.width * 0.75
        let y1 = frame.size.height * 0.25
        let y2 = frame.size.height * 0.75
        controllPoint1 = CGPoint(x: x1, y: y1)
        controllPoint2 = CGPoint(x: x2, y: y2)
    }
}
