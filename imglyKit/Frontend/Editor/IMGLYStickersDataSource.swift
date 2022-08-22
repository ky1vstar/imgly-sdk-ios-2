//
//  IMGLYStickersDataSource.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 23/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import Gifu

public protocol IMGLYStickersDataSourceDelegate: AnyObject, UICollectionViewDataSource {
    var stickers: [IMGLYSticker] { get }
}

open class IMGLYStickersDataSource: NSObject, IMGLYStickersDataSourceDelegate {
    public var stickers: [IMGLYSticker]
    public let allStickers: [IMGLYSticker]
    
    override init() {
        stickers = IMGLYStrickersManager.shared.dataArray.filter { $0 != nil }.map { $0! }
        self.allStickers = stickers
        super.init()
    }
    
    public init(stickers: [IMGLYSticker]) {
        self.stickers = stickers
        self.allStickers = stickers
        super.init()
    }
    
    func updateDataSource(term: String) {
        if term.count > 0 {
            self.stickers = self.allStickers.filter({ ($0.tags?.filter { $0.contains(term.lowercased()) }.count ?? 1) > 0 })
            return
        }
        self.stickers = self.allStickers
    }
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickersCollectionViewCellReuseIdentifier, for: indexPath) as! IMGLYStickerCollectionViewCell
       
         if let image = stickers[indexPath.row].image {
            cell.imageView.image = image
        } else if let dataGif = stickers[indexPath.row].dataGif {
            cell.imageView.prepareForAnimation(withGIFData: dataGif)
            cell.imageView.startAnimatingGIF()
        }
      
        return cell
    }
}
