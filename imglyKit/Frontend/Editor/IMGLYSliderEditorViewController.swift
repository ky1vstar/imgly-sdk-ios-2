//
//  IMGLYSliderEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 10/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

open class IMGLYSliderEditorViewController: IMGLYSubEditorViewController {
    
    // MARK: - Properties
    
    open fileprivate(set) lazy var slider: UISlider = {
       let slider = UISlider()
        slider.minimumValue = self.minimumValue
        slider.maximumValue = self.maximumValue
        slider.value = self.initialValue
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(IMGLYSliderEditorViewController.sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(IMGLYSliderEditorViewController.sliderTouchedUpInside(_:)), for: .touchUpInside)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    open var minimumValue: Float {
        // Subclasses should override this
        return -1
    }
    
    open var maximumValue: Float {
        // Subclasses should override this
        return 1
    }
    
    open var initialValue: Float {
        // Subclasses should override this
        return 0
    }
    
    fileprivate var changeTimer: Timer?
    fileprivate var updateInterval: TimeInterval = 0.01
    
    // MARK: - UIViewController

    override open func viewDidLoad() {
        super.viewDidLoad()

        shouldShowActivityIndicator = false
        configureViews()
    }
    
    // MARK: - IMGLYEditorViewController
    
    open override var enableZoomingInPreviewImage: Bool {
        return true
    }
    
    // MARK: - Configuration
    
    fileprivate func configureViews() {
        bottomContainerView.addSubview(slider)
        
        let views = ["slider" : slider]
        let metrics = ["margin" : 20]
        
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(==margin)-[slider]-(==margin)-|", options: [], metrics: metrics, views: views))
        bottomContainerView.addConstraint(NSLayoutConstraint(item: slider, attribute: .centerY, relatedBy: .equal, toItem: bottomContainerView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    // MARK: - Actions
    
    @objc fileprivate func sliderValueChanged(_ sender: UISlider?) {
        if changeTimer == nil {
            changeTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(IMGLYSliderEditorViewController.update(_:)), userInfo: nil, repeats: false)
        }
    }
    
    @objc fileprivate func sliderTouchedUpInside(_ sender: UISlider?) {
        changeTimer?.invalidate()
        
        valueChanged(slider.value)
        updatePreviewImageWithCompletion {
            self.changeTimer = nil
        }
    }
    
    @objc fileprivate func update(_ timer: Timer) {
        valueChanged(slider.value)
        updatePreviewImageWithCompletion {
            self.changeTimer = nil
        }
    }
    
    // MARK: - Subclasses
    
    open func valueChanged(_ value: Float) {
        // Subclasses should override this
    }

}
