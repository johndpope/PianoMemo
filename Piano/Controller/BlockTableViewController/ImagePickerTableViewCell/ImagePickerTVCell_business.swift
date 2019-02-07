//
//  ImageSelectionTVCell_business.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import Photos

private extension CollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        guard let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) else { return [] }
        return allLayoutAttributes.map { $0.indexPath }
    }
}

extension ImagePickerTableViewCell {
    
    internal func fetchResult(in collection: PHAssetCollection?) -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        let date = Date()
        allPhotosOptions.predicate = NSPredicate(
            format: "creationDate <= %@ && modificationDate <= %@",
            date as CVarArg,
            date as CVarArg)
        allPhotosOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate",
                             ascending: false)]
        
        if let collection = collection {
            return PHAsset.fetchAssets(in: collection, options: allPhotosOptions)
        } else {
            return PHAsset.fetchAssets(with: allPhotosOptions)
        }
    }
    
    internal func setSegmentControl() {
        segmentControl.removeAllSegments()
        userCollections
            .enumerateObjects({
                [weak self] (collection, offset, stop) in
                guard let self = self,
                    let segmentControl = self.segmentControl else { return }
                let index = segmentControl.numberOfSegments + offset
                segmentControl.insertSegment(withTitle: collection.localizedTitle,
                                             at: index,
                                             animated: false)
            })
    }
    
    
    internal func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }

    /// - Tag: UpdateAssets
    internal func updateCachedAssets() {
        // Update only if the view is visible.
//        guard isViewLoaded && view.window != nil else { return }

        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: -0.5 * visibleRect.width, dy: 0)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midX - previousPreheatRect.midX)
        guard delta > bounds.height / 3 else { return }

        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }

        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }

    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxX > old.maxX {
                added += [CGRect(x: old.maxX, y: new.origin.y,
                                 width: new.maxX - old.maxX, height: new.height)]
            }
            if old.minX > new.minX {
                added += [CGRect(x: new.minX, y: new.origin.y,
                                 width: old.minX - new.minX, height: new.height)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.maxX, y: new.origin.y,
                                   width: old.maxX - new.maxX, height: new.height)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: old.minX, y: new.origin.y,
                                   width: new.minX - old.minX, height: new.height)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}
