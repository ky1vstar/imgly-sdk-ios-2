//
//  IMGLYStickerSelectorViewController.swift
//  imglyKit2
//
//  Created by Dhaker Trimech on 16/08/2021.
//
import UIKit
import Gifu
import AVFoundation

public protocol IMGLYStickerSelectorViewDelegate: class {
    func didSelectSticker(_ sticker: IMGLYSticker)
}

let StickersCollectionViewCellSize = CGSize(width: 90, height: 90)
let StickersCollectionViewCellReuseIdentifier = "StickersCollectionViewCell"


class IMGLYStickerSelectorViewController: UIViewController {
    
    // MARK: - Properties
    open var stickersDataSource = IMGLYStickersDataSource()
    let StickersCollectionViewTag = 99
    
    open weak var delegate: IMGLYStickerSelectorViewDelegate?
    
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
        view.backgroundColor = .clear
        overlayBlurredBackgroundView()
        configureStickersCollectionView()

    }
  
    fileprivate func overlayBlurredBackgroundView() {
        let blurredBackgroundView = UIVisualEffectView()
        blurredBackgroundView.frame = view.frame
        blurredBackgroundView.effect = UIBlurEffect(style: .extraLight)
        view.addSubview(blurredBackgroundView)
    }
    
    fileprivate func configureStickersCollectionView() {
        
        let slideIdicator = UIView()
        slideIdicator.translatesAutoresizingMaskIntoConstraints = false
        slideIdicator.layer.cornerRadius = 2.0
        slideIdicator.backgroundColor = .lightGray
        view.addSubview(slideIdicator)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = StickersCollectionViewCellSize
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.tag = StickersCollectionViewTag
        collectionView.dataSource = stickersDataSource
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.register(IMGLYStickerCollectionViewCell.self, forCellWithReuseIdentifier: StickersCollectionViewCellReuseIdentifier)
        view.addSubview(collectionView)
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let views: [String : AnyObject] = ["collectionView" : collectionView, "slideIdicator" : slideIdicator]
        let metrics: [String : AnyObject] = [
            "slideIdicatorWidht" : 60 as AnyObject,
            "slideIdicatorHeight" : 4 as AnyObject,
            "topMargin" : 12 as AnyObject
        ]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[collectionView]|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[slideIdicator(==slideIdicatorWidht)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
           
        slideIdicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==topMargin)-[slideIdicator(==slideIdicatorHeight)]-(==topMargin)-[collectionView]-|", options: [], metrics: metrics, views: views))
    }
    
    override func viewDidLayoutSubviews() {
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }
        
        // setting x as 0 because we don't want users to move the frame side ways!! Only want straight up or down
        view.frame.origin = CGPoint(x: 0, y: self.pointOrigin!.y + translation.y)
        
        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: 0, y: 400)
                }
            }
        }
    }
}

extension IMGLYStickerSelectorViewController: UICollectionViewDelegate {
    // add selected sticker
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sticker = stickersDataSource.stickers[indexPath.row]
        self.delegate?.didSelectSticker(sticker)
    }
}

