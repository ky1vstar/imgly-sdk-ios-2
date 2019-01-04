//
//  IMGLYFocusEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYFocusEditorViewController: IMGLYSubEditorViewController {

    // MARK: - Properties
    
    open fileprivate(set) lazy var offButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("focus-editor.off", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_focus_off", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYFocusEditorViewController.turnOff(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var linearButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("focus-editor.linear", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_focus_linear", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYFocusEditorViewController.activateLinear(_:)), for: .touchUpInside)
        return button
        }()
    
    open fileprivate(set) lazy var radialButton: IMGLYImageCaptionButton = {
        let bundle = Bundle(for: type(of: self))
        let button = IMGLYImageCaptionButton()
        button.textLabel.text = NSLocalizedString("focus-editor.radial", tableName: nil, bundle: bundle, value: "", comment: "")
        button.imageView.image = UIImage(named: "icon_focus_radial", in: bundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(IMGLYFocusEditorViewController.activateRadial(_:)), for: .touchUpInside)
        return button
        }()
    
    fileprivate var selectedButton: IMGLYImageCaptionButton? {
        willSet(newSelectedButton) {
            self.selectedButton?.isSelected = false
        }
        
        didSet {
            self.selectedButton?.isSelected = true
        }
    }
    
    fileprivate lazy var circleGradientView: IMGLYCircleGradientView = {
        let view = IMGLYCircleGradientView()
        view.gradientViewDelegate = self
        view.isHidden = true
        view.alpha = 0
        return view
        }()
    
    fileprivate lazy var boxGradientView: IMGLYBoxGradientView = {
        let view = IMGLYBoxGradientView()
        view.gradientViewDelegate = self
        view.isHidden = true
        view.alpha = 0
        return view
        }()
    
    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("focus-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        configureButtons()
        configureGradientViews()
        
        selectedButton = offButton
        if fixedFilterStack.tiltShiftFilter.tiltShiftType != .off {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .off
            updatePreviewImage()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        circleGradientView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
        circleGradientView.centerGUIElements()
        
        boxGradientView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
        boxGradientView.centerGUIElements()
    }
    
    // MARK: - Configuration
    
    fileprivate func configureButtons() {
        let buttonContainerView = UIView()
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonContainerView)
        
        buttonContainerView.addSubview(offButton)
        buttonContainerView.addSubview(linearButton)
        buttonContainerView.addSubview(radialButton)
        
        let views = [
            "buttonContainerView" : buttonContainerView,
            "offButton" : offButton,
            "linearButton" : linearButton,
            "radialButton" : radialButton
        ]
        
        let metrics = [
            "buttonWidth" : 90
        ]
        
        // Button Constraints
        
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[offButton(==buttonWidth)][linearButton(==offButton)][radialButton(==offButton)]|", options: [], metrics: metrics, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[offButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[linearButton]|", options: [], metrics: nil, views: views))
        buttonContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[radialButton]|", options: [], metrics: nil, views: views))
        
        // Container Constraints
        
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[buttonContainerView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraint(NSLayoutConstraint(item: buttonContainerView, attribute: .centerX, relatedBy: .equal, toItem: bottomContainerView, attribute: .centerX, multiplier: 1, constant: 0))
    }
    
    fileprivate func configureGradientViews() {
        view.addSubview(circleGradientView)
        view.addSubview(boxGradientView)
    }
    
    // MARK: - Actions
    
    @objc fileprivate func turnOff(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectedButton = sender
        hideBoxGradientView()
        hideCircleGradientView()
        updateFilterTypeAndPreview()
    }
    
    @objc fileprivate func activateLinear(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectedButton = sender
        hideCircleGradientView()
        showBoxGradientView()
        updateFilterTypeAndPreview()
    }
    
    @objc fileprivate func activateRadial(_ sender: IMGLYImageCaptionButton) {
        if selectedButton == sender {
            return
        }
        
        selectedButton = sender
        hideBoxGradientView()
        showCircleGradientView()
        updateFilterTypeAndPreview()
    }
    
    // MARK: - Helpers
    
    fileprivate func updateFilterTypeAndPreview() {
        if selectedButton == linearButton {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .box
            fixedFilterStack.tiltShiftFilter.controlPoint1 = boxGradientView.normalizedControlPoint1
            fixedFilterStack.tiltShiftFilter.controlPoint2 = boxGradientView.normalizedControlPoint2
        } else if selectedButton == radialButton {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .circle
            fixedFilterStack.tiltShiftFilter.controlPoint1 = circleGradientView.normalizedControlPoint1
            fixedFilterStack.tiltShiftFilter.controlPoint2 = circleGradientView.normalizedControlPoint2
        } else if selectedButton == offButton {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .off
        }
        
        updatePreviewImage()
    }
    
    fileprivate func showCircleGradientView() {
        circleGradientView.isHidden = false
        UIView.animate(withDuration: TimeInterval(0.15), animations: {
            self.circleGradientView.alpha = 1.0
        })
    }
    
    fileprivate func hideCircleGradientView() {
        UIView.animate(withDuration: TimeInterval(0.15), animations: {
            self.circleGradientView.alpha = 0.0
            },
            completion: { finished in
                if(finished) {
                    self.circleGradientView.isHidden = true
                }
            }
        )
    }
    
    fileprivate func showBoxGradientView() {
        boxGradientView.isHidden = false
        UIView.animate(withDuration: TimeInterval(0.15), animations: {
            self.boxGradientView.alpha = 1.0
        })
    }
    
    fileprivate func hideBoxGradientView() {
        UIView.animate(withDuration: TimeInterval(0.15), animations: {
            self.boxGradientView.alpha = 0.0
            },
            completion: { finished in
                if(finished) {
                    self.boxGradientView.isHidden = true
                }
            }
        )
    }

}

extension IMGLYFocusEditorViewController: IMGLYGradientViewDelegate {
    public func userInteractionStarted() {
        fixedFilterStack.tiltShiftFilter.tiltShiftType = .off
        updatePreviewImage()
    }
    
    public func userInteractionEnded() {
        updateFilterTypeAndPreview()
    }
    
    public func controlPointChanged() {
        
    }
}
