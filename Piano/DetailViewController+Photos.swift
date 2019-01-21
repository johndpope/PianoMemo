//
//  DetailViewController+Photo.swift
//  Piano
//
//  Created by hoemoon on 21/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

extension DetailViewController: PHPhotoLibraryChangeObserver {
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

extension DetailViewController: UICollectionViewDataSource {
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
            }
        }
        return cell
    }
}

extension DetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photoFetchResult.object(at: indexPath.item)

        // TODO: 선택한 사진 가져와서 이미지 만들기
        // TODO: 이미지에서 영구 id 따와서 노트 컨텐츠 업데이트
        // TODO: 실제 이미지 노트에서 보이기
    }
}

extension DetailViewController {
    func resetCachedAssets() {
        cacheManager.stopCachingImagesForAllAssets()
    }

    func updateCachedAssets() {

    }
}
