//
//  ImageInputView.swift
//  Piano
//
//  Created by hoemoon on 22/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

protocol HandleSelectedPhotoDelegate: class {
    func handle(selected asset: PHAsset)
}

class ImageInputView: UIInputView {
    var photoFetchResult: PHFetchResult<PHAsset>!
    var thumbnailSize: CGSize!
    var previousPreheatRect = CGRect.zero

    private var height = CGFloat()
    lazy var cacheManager = PHCachingImageManager()

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!

    var photoDataSource: UICollectionViewDataSource!
    weak var delegate: HandleSelectedPhotoDelegate?

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
//        allowsSelfSizing = true
        translatesAutoresizingMaskIntoConstraints = false
//        invalidateIntrinsicContentSize()
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.inset(by: safeAreaInsets).width
        height = UIScreen.main.bounds.height * 0.40
        invalidateIntrinsicContentSize()

        let staticWidth: CGFloat = 100
        let isPotrait = UIScreen.main.bounds.height > UIScreen.main.bounds.width
        let columnCount = isPotrait ? 4 : (width / staticWidth)
        let itemWidth = (width / columnCount) - 1

        collectionViewFlowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)

        let scale = UIScreen.main.scale
        let cellSize = collectionViewFlowLayout.itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }

    func setup(with delegate: HandleSelectedPhotoDelegate) {
        PHPhotoLibrary.shared().register(self)
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photoFetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        collectionView.dataSource = self
        collectionView.delegate = self
        self.delegate = delegate
        resetCachedAssets()
    }
}

extension ImageInputView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photoFetchResult.object(at: indexPath.item)
        delegate?.handle(selected: asset)
    }
}

extension ImageInputView: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: photoFetchResult)
            else { return }
        DispatchQueue.main.sync {
            photoFetchResult = changes.fetchResultAfterChanges

            if changes.hasIncrementalChanges {
                guard let collectionView = self.collectionView else { return }
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(
                            at: removed.map { IndexPath(item: $0, section: 0) }
                        )
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(
                            at: inserted.map { IndexPath(item: $0, section: 0) }
                        )
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(
                            at: IndexPath(item: fromIndex, section: 0), to: IndexPath(item: toIndex, section: 0)
                        )
                    }
                })
                if let changed = changes.changedIndexes, !changed.isEmpty {
                    collectionView.reloadItems(
                        at: changed.map({ IndexPath(item: $0, section: 0) })
                    )
                }
            } else {
                collectionView.reloadData()
            }
            resetCachedAssets()
        }
    }
}

extension ImageInputView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoFetchResult.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = photoFetchResult.object(at: indexPath.item)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.id, for: indexPath) as? PhotoCell else { fatalError() }

        cell.representedAssetIdentifier = asset.localIdentifier
        cacheManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil) { image, _ in

            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
                cell.activityIndicatorView.stopAnimating()
            }
        }
        return cell
    }
}

extension ImageInputView {
    private func resetCachedAssets() {
        cacheManager.stopCachingImagesForAllAssets()
    }

    private func updateCachedAssets() {

    }
}
