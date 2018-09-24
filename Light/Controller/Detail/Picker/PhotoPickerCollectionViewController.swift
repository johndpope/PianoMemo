//
//  PhotoPickerCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 11..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import PhotosUI

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class PhotoPickerCollectionViewController: UICollectionViewController, NoteEditable, CollectionRegisterable {
    var note: Note!
    
    private var allPhotos: PHFetchResult<PHAsset>? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.collectionView?.reloadData()
                self.selectCollectionView()
            }
        }
    }
    fileprivate lazy var imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    let locationMananger = CLLocationManager()
    var identifiersToDelete: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        registerHeaderView(PianoReusableView.self)
        registerCell(PHAssetCell.self)
        collectionView?.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        locationMananger.delegate = self
        
        Access.photoRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            PHPhotoLibrary.shared().register(self)
            self.fetchImages()
            Access.locationRequest(from: self, manager: self.locationMananger, success: nil)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(invalidLayout), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    private func selectCollectionView() {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            self.allPhotos?.enumerateObjects(options: NSEnumerationOptions.concurrent, using: { (asset, item, _) in
                if self.note.photoIdentifiers.contains(asset.localIdentifier) {
                    let indexPath = IndexPath(item: item, section: 0)
                    DispatchQueue.main.async {
                        self.collectionView?.selectItem(at: indexPath, animated: true, scrollPosition: .top)
                    }
                }
            })
        }
    }
    
    internal func fetchImages(){
        
        //이미지 가져오기
        let allPhotosOptions = PHFetchOptions()
        let date = Date()
        allPhotosOptions.predicate = NSPredicate(format: "creationDate <= %@ && modificationDate <= %@ && mediaType = %d", date as CVarArg, date as CVarArg, PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    }
    


}

extension PhotoPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        //selectedIndexPath를 돌아서 뷰 모델을 추출해내고, 노트의 기존 reminder의 identifier와 비교해서 다르다면 노트에 삽입해주기
        

        let identifiersToAdd = collectionView?.indexPathsForSelectedItems?.compactMap({ (indexPath) -> String? in
            return allPhotos?.object(at: indexPath.item).localIdentifier
        })
        
        
        guard let privateContext = note.managedObjectContext else {return }
        
        privateContext.perform { [weak self] in
            guard let `self` = self else { return }
            
            if let identifiersToAdd = identifiersToAdd {
                identifiersToAdd.forEach { identifier in
                    if !self.note.photoIdentifiers.contains(identifier) {
                        let photo = Photo(context: privateContext)
                        photo.identifier = identifier
                        photo.addToNoteCollection(self.note)
                    }
                }
            }
            
            self.identifiersToDelete.forEach { identifier in
                guard let photo = self.note.photoCollection?.filter({ (value) -> Bool in
                    guard let photo = value as? Photo,
                        let existIdentifier = photo.identifier else { return false }
                    return identifier == existIdentifier
                }).first as? Photo else { return }
                privateContext.delete(photo)
            }
            
            privateContext.saveIfNeeded()
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension PhotoPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let data = allPhotos?.object(at: indexPath.item) else { return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! PHAssetCell
        cell.imageManager = imageManager
        cell.collectionView = collectionView
        cell.data = data
        return cell
    }
    
    
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return dataSource.count
//    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotos?.count ?? 0
    }
    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PianoReusableView.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
//        return reusableView
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: 100, height: 33)
//    }
}

extension PhotoPickerCollectionViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = allPhotos?.object(at: indexPath.item).localIdentifier else { return }
        
        if let index = identifiersToDelete.index(of: identifier) {
            identifiersToDelete.remove(at: index)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let identifier = allPhotos?.object(at: indexPath.item).localIdentifier else { return }
        
        if note.photoIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension PhotoPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return allPhotos?.firstObject?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return allPhotos?.firstObject?.size(view: collectionView) ?? CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return allPhotos?.firstObject?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return allPhotos?.firstObject?.minimumInteritemSpacing ?? 0
    }
    
}

extension PhotoPickerCollectionViewController {
    @objc private func invalidLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    // MARK: Asset Caching
    
    fileprivate func updateCachedAssets() {
        // Update only if the collectionView is visible.
        guard let collectionView = collectionView,
            let fetchResult = allPhotos,
            !collectionView.isHidden else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > collectionView.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        let scale = UIScreen.main.scale
        guard let asset = allPhotos?.firstObject else { return }
        
        let thumbnailSize = CGSize(width: asset.size(view: collectionView).width * scale, height: asset.size(view: collectionView).height * scale)
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

extension PhotoPickerCollectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let unwrapallPhotos = allPhotos,
            let changes = changeInstance.changeDetails(for: unwrapallPhotos)
            else { return }
        
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.\
            allPhotos = changes.fetchResultAfterChanges
            
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, !changed.isEmpty {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}



extension PhotoPickerCollectionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            // Disable your app's location features
            Alert.location(from: self)
            break
            
        case .authorizedWhenInUse:
            break
            
        case .authorizedAlways:
            break
            
        case .notDetermined:
            
            break
        }
    }
}
