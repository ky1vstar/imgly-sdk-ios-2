//
//  IMGLYTextColorSelectorView.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 05/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public protocol IMGLYTextColorSelectorViewDelegate: class {
    func textColorSelectorView(_ selectorView: IMGLYTextColorSelectorView, didSelectColor color: UIColor)
}

open class IMGLYTextColorSelectorView: UIScrollView {
    open weak var menuDelegate: IMGLYTextColorSelectorViewDelegate?
    
    fileprivate var colorArray = [UIColor]()
    fileprivate var buttonArray = [IMGLYColorButton]()
    
    fileprivate let kButtonYPosition = CGFloat(22)
    fileprivate let kButtonXPositionOffset = CGFloat(5)
    fileprivate let kButtonDistance = CGFloat(10)
    fileprivate let kButtonSideLength = CGFloat(50)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        self.autoresizesSubviews = false
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        configureColorArray()
        configureColorButtons()
    }
    
    fileprivate func configureColorArray() {
        colorArray = [
            UIColor.white,
            UIColor.black,
            UIColor(red: CGFloat(0xec / 255.0), green:CGFloat(0x37 / 255.0), blue:CGFloat(0x13 / 255.0), alpha:1.0),
            UIColor(red: CGFloat(0xfc / 255.0), green:CGFloat(0xc0 / 255.0), blue:CGFloat(0x0b / 255.0), alpha:1.0),
            UIColor(red: CGFloat(0xa9 / 255.0), green:CGFloat(0xe9 / 255.0), blue:CGFloat(0x0e / 255.0), alpha:1.0),
            UIColor(red: CGFloat(0x0b / 255.0), green:CGFloat(0x6a / 255.0), blue:CGFloat(0xf9 / 255.0), alpha:1.0),
            UIColor(red: CGFloat(0xff / 255.0), green:CGFloat(0xff / 255.0), blue:CGFloat(0x00 / 255.0), alpha:1.0),
            UIColor(red: CGFloat(0xb5 / 255.0), green:CGFloat(0xe5 / 255.0), blue:CGFloat(0xff / 255.0), alpha:1.0),
            UIColor(red: CGFloat(0xff / 255.0), green:CGFloat(0xb5 / 255.0), blue:CGFloat(0xe0 / 255.0), alpha:1.0)]
    }
    
    fileprivate func configureColorButtons() {
        for color in colorArray {
            let button = IMGLYColorButton()
            self.addSubview(button)
            button.addTarget(self, action: #selector(IMGLYTextColorSelectorView.colorButtonTouchedUpInside(_:)), for: .touchUpInside)
            buttonArray.append(button)
            button.backgroundColor = color
            button.hasFrame = true
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutColorButtons()
    }
    
    fileprivate func layoutColorButtons() {
        var xPosition = kButtonXPositionOffset
        for i in 0..<colorArray.count {
            let button = buttonArray[i]
            button.frame = CGRect(x: xPosition,
                y: kButtonYPosition,
                width: kButtonSideLength,
                height: kButtonSideLength)
            xPosition += (kButtonDistance + kButtonSideLength)
        }
        buttonArray[0].hasFrame = true
        contentSize = CGSize(width: xPosition - kButtonDistance + kButtonXPositionOffset, height: 0)
    }
    
    @objc fileprivate func colorButtonTouchedUpInside(_ button:UIButton) {
        menuDelegate?.textColorSelectorView(self, didSelectColor: button.backgroundColor!)
    }
}
