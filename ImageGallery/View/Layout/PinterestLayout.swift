//
//  PinterestLayout.swift
//  ImageGallery
//
//  Created by Ahmed Abaza on 17/02/2022.
//

import UIKit

@IBDesignable
class PinterestLayout: UICollectionViewLayout {
    weak var delegate: PinterestLayoutDelegate?

    
    @IBInspectable private let numberOfColumns = 2
    @IBInspectable private let cellPadding: CGFloat = 6
    
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    
    private var contentHeight: CGFloat = 0

    ///The width of the content of the collectionview based on its width and insets.
    private var contentWidth: CGFloat {
        guard let collectionView = self.collectionView else { return 0 }
        
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    
    override var collectionViewContentSize: CGSize {
      return CGSize(width: contentWidth, height: contentHeight)
    }
    
    
    override func prepare() {
        
        guard let collectionView = self.collectionView, self.layoutAttributes.count < collectionView.numberOfItems(inSection: 0)
        else { return }
        
        self.layoutAttributes.removeAll()
        
        let colWidth = self.contentWidth / CGFloat(self.numberOfColumns)
        
        var xOffset = [CGFloat]()
        
        for col in 0 ..< self.numberOfColumns {
            xOffset.append(CGFloat(col) * colWidth)
        }
        
        var col = 0
        
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
        for item in .zero ..< collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let photoHeight = delegate?.collectionView(collectionView,heightForPhotoAtIndexPath: indexPath) ?? 180
            let height = cellPadding * 2 + photoHeight
            
            let frame = CGRect(
                x: xOffset[col],
                y: yOffset[col],
                width: colWidth,
                height: height
            )
            
            let insetFrame = frame.insetBy(dx: self.cellPadding, dy: self.cellPadding)
              
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            
            self.layoutAttributes.append(attributes)
            
            self.contentHeight = max(self.contentHeight, frame.maxY)
            yOffset[col] = yOffset[col] + height
            
            col = col < (self.numberOfColumns - 1) ? (col + 1) : 0
          }
    }
    
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
        
        // Loop through the cache and look for items in the rect
        for itemAttributes in self.layoutAttributes {
            if itemAttributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(itemAttributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < self.layoutAttributes.count else {return nil}
        return self.layoutAttributes[indexPath.item]
    }

}



protocol PinterestLayoutDelegate: AnyObject {
  func collectionView( _ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
}
