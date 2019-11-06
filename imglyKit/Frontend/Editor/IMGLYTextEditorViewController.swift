//
//  TextEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 17/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

private let FontSizeInTextField = CGFloat(20)
private let TextFieldHeight = CGFloat(40)
private let TextLabelInitialMargin = CGFloat(40)
private let MinimumFontSize = CGFloat(12.0)

open class IMGLYTextEditorViewController: IMGLYSubEditorViewController {
    
    // MARK: - Properties
    
    fileprivate var textColor = UIColor.white
    fileprivate var fontName = ""
    fileprivate var currentTextSize = CGFloat(0)
    fileprivate var maximumFontSize = CGFloat(0)
    fileprivate var panOffset = CGPoint.zero
    fileprivate var fontSizeAtPinchBegin = CGFloat(0)
    fileprivate var distanceAtPinchBegin = CGFloat(0)
    fileprivate var beganTwoFingerPitch = false
    
    open fileprivate(set) lazy var textColorSelectorView: IMGLYTextColorSelectorView = {
        let view = IMGLYTextColorSelectorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.menuDelegate = self
        return view
        }()
    
    open fileprivate(set) lazy var textClipView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
        }()
    
    open fileprivate(set) lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.backgroundColor = UIColor(white:0.0, alpha:0.5)
        textField.text = ""
        textField.textColor = self.textColor
        textField.clipsToBounds = false
        textField.contentVerticalAlignment = .center
        textField.returnKeyType = UIReturnKeyType.done
        return textField
        }()
    
    open fileprivate(set) lazy var textLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0.0
        label.backgroundColor = UIColor(white:0.0, alpha:0.0)
        label.textColor = self.textColor
        label.textAlignment = NSTextAlignment.center
        label.clipsToBounds = true
        label.isUserInteractionEnabled = true
        return label
        }()
    
    open fileprivate(set) lazy var fontSelectorContainerView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
        }()
    
    open fileprivate(set) lazy var fontSelectorView: IMGLYFontSelectorView = {
        let selector = IMGLYFontSelectorView()
        selector.translatesAutoresizingMaskIntoConstraints = false
        selector.selectorDelegate = self
        return selector
    }()
    
    // MAKR: - Initializers
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIViewController

    override open func viewDidLoad() {
        super.viewDidLoad()

        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("text-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        IMGLYInstanceFactory.fontImporter().importFonts()
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        configureColorSelectorView()
        configureTextClipView()
        configureTextField()
        configureTextLabel()
        configureFontSelectorView()
        registerForKeyboardNotifications()
        configureGestureRecognizers()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        textClipView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
    }
    
    // MARK: - SubEditorViewController
    
    open override func tappedDone(_ sender: UIBarButtonItem?) {
        fixedFilterStack.textFilter.text = textLabel.text ?? ""
        fixedFilterStack.textFilter.color = textColor
        fixedFilterStack.textFilter.fontName = fontName
        fixedFilterStack.textFilter.frame = transformedTextFrame()
        fixedFilterStack.textFilter.fontScaleFactor = currentTextSize / previewImageView.visibleImageFrame.size.height
        
        updatePreviewImageWithCompletion {
            super.tappedDone(sender)
        }
    }
    
    // MARK: - Configuration
    
    fileprivate func configureColorSelectorView() {
        bottomContainerView.addSubview(textColorSelectorView)

        let views = [
            "textColorSelectorView" : textColorSelectorView
        ]
        
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[textColorSelectorView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textColorSelectorView]|", options: [], metrics: nil, views: views))
    }
    
    fileprivate func configureTextClipView() {
        view.addSubview(textClipView)
    }
    
    fileprivate func configureTextField() {
        view.addSubview(textField)
        textField.frame = CGRect(x: 0, y: view.bounds.size.height, width: view.bounds.size.width, height: TextFieldHeight)
    }
    
    fileprivate func configureTextLabel() {
        textClipView.addSubview(textLabel)
    }
    
    fileprivate func configureFontSelectorView() {
        view.addSubview(fontSelectorContainerView)
        fontSelectorContainerView.contentView.addSubview(fontSelectorView)
        
        let views = [
            "fontSelectorContainerView" : fontSelectorContainerView,
            "fontSelectorView" : fontSelectorView
        ] as [String : Any]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[fontSelectorContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[fontSelectorContainerView]|", options: [], metrics: nil, views: views))
        
        fontSelectorContainerView.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[fontSelectorView]|", options: [], metrics: nil, views: views))
        fontSelectorContainerView.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[fontSelectorView]|", options: [], metrics: nil, views: views))
    }
    
    fileprivate func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(IMGLYTextEditorViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    fileprivate func configureGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(IMGLYTextEditorViewController.handlePan(_:)))
        textLabel.addGestureRecognizer(panGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(IMGLYTextEditorViewController.handlePinch(_:)))
        view.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    // MARK: - Gesture Handling
    
    @objc fileprivate func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: textClipView)
        
        if gestureRecognizer.state == .began {
            panOffset = gestureRecognizer.location(in: textLabel)
        }
        
        var frame = textLabel.frame
        frame.origin.x = location.x - panOffset.x
        frame.origin.y = location.y - panOffset.y
        textLabel.frame = frame
    }
    
    @objc fileprivate func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            fontSizeAtPinchBegin = currentTextSize
            beganTwoFingerPitch = false
        }
        
        if gestureRecognizer.numberOfTouches > 1 {
            let point1 = gestureRecognizer.location(ofTouch: 0, in:view)
            let point2 = gestureRecognizer.location(ofTouch: 1, in:view)
            if  !beganTwoFingerPitch {
                beganTwoFingerPitch = true
                distanceAtPinchBegin = calculateNewFontSizeBasedOnDistanceBetweenPoint(point1, and: point2)
            }
            
            let distance = calculateNewFontSizeBasedOnDistanceBetweenPoint(point1, and: point2)
            currentTextSize = fontSizeAtPinchBegin - (distanceAtPinchBegin - distance) / 2.0
            currentTextSize = max(MinimumFontSize, currentTextSize)
            currentTextSize = min(maximumFontSize, currentTextSize)
            textLabel.font = UIFont(name:fontName, size: currentTextSize)
            updateTextLabelFrameForCurrentFont()
        }
    }
    
    // MARK: - Notification Handling
    
    @objc fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        if let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
            textField.frame = CGRect(x: 0, y: view.frame.size.height - keyboardFrame.size.height - TextFieldHeight, width: view.frame.size.width, height: TextFieldHeight)
        }
    }
    
    // MARK: - Helpers
    
    fileprivate func hideTextField() {
        UIView.animate(withDuration: 0.2, animations: {
            self.textField.alpha = 0.0
        }) 
    }
    
    fileprivate func showTextLabel() {
        UIView.animate(withDuration: 0.2, animations: {
            self.textLabel.alpha = 1.0
        }) 
    }
    
    fileprivate func calculateInitialFontSize() {
        if let text = textLabel.text {
            currentTextSize = 1.0
            
            var size = CGSize.zero
            if !text.isEmpty {
                repeat {
                    currentTextSize += 1.0
                    let font = UIFont(name: fontName, size: currentTextSize)
                    size = text.size(withAttributes: [ NSAttributedString.Key.font: font as AnyObject ])
                } while (size.width < (view.frame.size.width - TextLabelInitialMargin))
            }
        }
    }
    
    fileprivate func calculateMaximumFontSize() {
        var size = CGSize.zero
        
        if let text = textLabel.text {
            if !text.isEmpty {
                maximumFontSize = currentTextSize
                repeat {
                    maximumFontSize += 1.0
                    let font = UIFont(name: fontName, size: maximumFontSize)
                    size = text.size(withAttributes: [ NSAttributedString.Key.font: font as AnyObject ])
                } while (size.width < self.view.frame.size.width)
            }
        }
    }
    
    fileprivate func setInitialTextLabelSize() {
        calculateInitialFontSize()
        calculateMaximumFontSize()
        
        textLabel.font = UIFont(name: fontName, size: currentTextSize)
        textLabel.sizeToFit()
        textLabel.frame.origin.x = TextLabelInitialMargin / 2.0 - textClipView.frame.origin.x
        textLabel.frame.origin.y = -textLabel.frame.size.height / 2.0 + textClipView.frame.height / 2.0
    }
    
    fileprivate func calculateNewFontSizeBasedOnDistanceBetweenPoint(_ point1: CGPoint, and point2: CGPoint) -> CGFloat {
        let diffX = point1.x - point2.x
        let diffY = point1.y - point2.y
        return sqrt(diffX * diffX + diffY  * diffY)
    }
    
    fileprivate func updateTextLabelFrameForCurrentFont() {
        // resize and keep the text centered
        let frame = textLabel.frame
        textLabel.sizeToFit()
        
        let diffX = frame.size.width - textLabel.frame.size.width
        let diffY = frame.size.height - textLabel.frame.size.height
        textLabel.frame.origin.x += (diffX / 2.0)
        textLabel.frame.origin.y += (diffY / 2.0)
    }
    
    fileprivate func transformedTextFrame() -> CGRect {
        var origin = textLabel.frame.origin
        origin.x = origin.x / previewImageView.visibleImageFrame.size.width
        origin.y = origin.y / previewImageView.visibleImageFrame.size.height
        
        var size = textLabel.frame.size
        size.width = size.width / textLabel.frame.size.width
        size.height = size.height / textLabel.frame.size.height
        
        return CGRect(origin: origin, size: size)
    }
}

extension IMGLYTextEditorViewController: IMGLYTextColorSelectorViewDelegate {
    public func textColorSelectorView(_ selectorView: IMGLYTextColorSelectorView, didSelectColor color: UIColor) {
        textColor = color
        textField.textColor = color
        textLabel.textColor = color
    }
}

extension IMGLYTextEditorViewController: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        hideTextField()
        textLabel.text = textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        setInitialTextLabelSize()
        showTextLabel()
        navigationItem.rightBarButtonItem?.isEnabled = true
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension IMGLYTextEditorViewController: IMGLYFontSelectorViewDelegate {
    public func fontSelectorView(_ fontSelectorView: IMGLYFontSelectorView, didSelectFontWithName fontName: String) {
        fontSelectorContainerView.removeFromSuperview()
        self.fontName = fontName
        textField.font = UIFont(name: fontName, size: FontSizeInTextField)
        textField.becomeFirstResponder()
    }
}
