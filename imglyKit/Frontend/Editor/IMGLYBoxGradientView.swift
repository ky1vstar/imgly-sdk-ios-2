//
// Created by Carsten Przyluczky on 01/03/15.
// Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public struct Line {
    public let start: CGPoint
    public let end: CGPoint
}

open class IMGLYBoxGradientView : UIView {
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
    
    // MARK:- setup
    
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
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:#selector(IMGLYBoxGradientView.handlePanGesture(_:)))
        addGestureRecognizer(panGestureRecognizer)
        crossImageView_.addGestureRecognizer(panGestureRecognizer)
    }
    
    open func configurePinchGestureRecognizer() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target:self, action:#selector(IMGLYBoxGradientView.handlePinchGesture(_:)))
        addGestureRecognizer(pinchGestureRecognizer)
    }
    
    // MARK:- Drawing
    
    open func diagonalLengthOfFrame() -> CGFloat {
        return sqrt(frame.size.width * frame.size.width +
            frame.size.height * frame.size.height)
    }
    
    open func normalizedOrtogonalVector() -> CGPoint {
        let diffX = controllPoint2.x - controllPoint1.x
        let diffY = controllPoint2.y - controllPoint1.y
        
        let diffLength = sqrt(diffX * diffX + diffY  * diffY)
        
        return CGPoint( x: -diffY / diffLength, y: diffX / diffLength)
    }
    
    open func distanceBetweenControlPoints() -> CGFloat {
        let diffX = controllPoint2.x - controllPoint1.x
        let diffY = controllPoint2.y - controllPoint1.y
        
        return sqrt(diffX * diffX + diffY  * diffY)
    }
    
    /*
    This method appears a bit tricky, but its not.
    We just take the vector that connects the control points,
    and rotate it by 90 degrees. Then we normalize it and give it a total
    lenghts that is the lenght of the diagonal, of the Frame.
    That diagonal is the longest line that can be drawn in the Frame, therefore its a good orientation.
    */
    
    open func lineForControlPoint(_ controlPoint:CGPoint) -> Line {
        let ortogonalVector = normalizedOrtogonalVector()
        let halfDiagonalLengthOfFrame = diagonalLengthOfFrame()
        let scaledOrthogonalVector = CGPoint(x: halfDiagonalLengthOfFrame * ortogonalVector.x,
            y: halfDiagonalLengthOfFrame * ortogonalVector.y)
        let lineStart = CGPoint(x: controlPoint.x - scaledOrthogonalVector.x,
            y: controlPoint.y - scaledOrthogonalVector.y)
        let lineEnd = CGPoint(x: controlPoint.x + scaledOrthogonalVector.x,
            y: controlPoint.y + scaledOrthogonalVector.y)
        return Line(start: lineStart, end: lineEnd);
    }
    
    open func addLineForControlPoint1ToPath(_ path:UIBezierPath) {
        let line = lineForControlPoint(controllPoint1)
        path.move(to: line.start)
        path.addLine(to: line.end)
    }
    
    open func addLineForControlPoint2ToPath(_ path:UIBezierPath) {
        let line = lineForControlPoint(controllPoint2)
        path.move(to: line.start)
        path.addLine(to: line.end)
    }
    
    open override func draw(_ rect: CGRect) {
        let aPath = UIBezierPath()
        UIColor(white: 0.8, alpha: 1.0).setStroke()
        addLineForControlPoint1ToPath(aPath)
        addLineForControlPoint2ToPath(aPath)
        aPath.close()
        
        aPath.lineWidth = 1
        aPath.stroke()
    }
    
    // MARK:- gesture handling
    open func calculateCenterPointFromOtherControlPoints() {
        centerPoint = CGPoint(x: (controllPoint1.x + controllPoint2.x) / 2.0,
            y: (controllPoint1.y + controllPoint2.y) / 2.0);
    }
    
    open func informDeletageAboutRecognizerStates(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            if gradientViewDelegate != nil {
                gradientViewDelegate!.userInteractionStarted()
            }
        }
        if recognizer.state == .ended ||
            recognizer.state == .cancelled {
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
    
    open func isPoint(_ point:CGPoint, inRect rect:CGRect) -> Bool {
        let top = rect.origin.y
        let bottom = top + rect.size.height
        let left = rect.origin.x
        let right = left + rect.size.width
        let inRectXAxis = point.x > left && point.x < right
        let inRectYAxis = point.y > top && point.y < bottom
        return (inRectXAxis && inRectYAxis)
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
        let x1 = frame.size.width * 0.5
        let x2 = frame.size.width * 0.5
        let y1 = frame.size.height * 0.25
        let y2 = frame.size.height * 0.75
        controllPoint1 = CGPoint(x: x1, y: y1)
        controllPoint2 = CGPoint(x: x2, y: y2)
    }
}
