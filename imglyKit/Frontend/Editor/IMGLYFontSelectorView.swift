//
//  IMGLYFontSelectorView.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 06/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public protocol IMGLYFontSelectorViewDelegate: class {
    func fontSelectorView(_ fontSelectorView: IMGLYFontSelectorView, didSelectFontWithName fontName: String)
}

open class IMGLYFontSelectorView: UIScrollView {
    open weak var selectorDelegate: IMGLYFontSelectorViewDelegate?
    
    fileprivate let kDistanceBetweenButtons = CGFloat(60)
    fileprivate let kFontSize = CGFloat(28)
    fileprivate var fontNames = [String]()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {       
        fontNames = IMGLYInstanceFactory.availableFontsList
        configureFontButtons()
    }
    
    fileprivate func configureFontButtons() {
        for fontName in fontNames {
            let button = UIButton(type: .custom)
            button.setTitle(fontName, for: [])
            button.contentHorizontalAlignment = .center
            
            if let font = UIFont(name: fontName, size: kFontSize) {
                button.titleLabel?.font = font
                addSubview(button)
                button.addTarget(self, action: #selector(IMGLYFontSelectorView.buttonTouchedUpInside(_:)), for: .touchUpInside)
            }
        }
    }
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        for index in 0..<subviews.count {
            if let button = subviews[index] as? UIButton {
                button.frame = CGRect(x: 0,
                    y: CGFloat(index) * kDistanceBetweenButtons,
                    width: frame.size.width,
                    height: kDistanceBetweenButtons)
            }
        }
        contentSize = CGSize(width: frame.size.width - 1.0, height: kDistanceBetweenButtons * CGFloat(subviews.count - 2))
    }
    
    @objc fileprivate func buttonTouchedUpInside(_ button: UIButton) {
        selectorDelegate?.fontSelectorView(self, didSelectFontWithName: button.titleLabel!.text!)
    }
 }
