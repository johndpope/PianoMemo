//
//  PhotoPickerCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerCollectionViewController: UICollectionViewController {
    
    var note: Note!
    
    private let imageManager = PHCachingImageManager()
    private var photoFetchResult = PHFetchResult<PHAsset>()
    private var fetchedAssets = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumInteritemSpacing = 2
            flowLayout.minimumLineSpacing = 2
        }
        fetch()
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        guard parent == nil else {return}
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = nil
    }
    
    @IBAction private func close(_ button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
}

extension PhotoPickerCollectionViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    private func request() {
        //        guard let photoCollection = note.photoCollection else {return}
        guard let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject else {return}
        photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
        let indexSet = IndexSet(0...photoFetchResult.count - 1)
        //        fetchedAssets = photoFetchResult.objects(at: indexSet).reversed().filter { asset in
        //            !photoCollection.contains(where: {($0 as! Photo).identifier == asset.localIdentifier})
        //        }
        fetchedAssets = photoFetchResult.objects(at: indexSet).reversed()
    }
    
}

extension PhotoPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: collectionView.bounds.height, height: collectionView.bounds.height)
        }
        var portCellNum: CGFloat = 3
        var landCellNum: CGFloat = 5
        if UIDevice.current.userInterfaceIdiom == .pad {
            portCellNum = portCellNum * 2
            landCellNum = landCellNum * 2
        }
        let portCutSpacing = flowLayout.minimumInteritemSpacing * (portCellNum - 1)
        let landCutSpacing = flowLayout.minimumInteritemSpacing * (landCellNum - 1)
        var cellSize = collectionView.bounds.height
        if flowLayout.scrollDirection == .vertical {
            cellSize = floor((collectionView.bounds.width - portCutSpacing) / portCellNum)
            if UIApplication.shared.statusBarOrientation.isLandscape {
                cellSize = floor((collectionView.bounds.width - landCutSpacing) / landCellNum)
            }
        }
        return CGSize(width: cellSize, height: cellSize)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        requestImage(indexPath, size: PHImageManagerMinimumSize) { (image, error) in
            cell.configure(image, isLinked: self.note.photoCollection?.contains(self.fetchedAssets[indexPath.row]))
        }
        return cell
    }
    
    private func requestImage(_ indexPath: IndexPath, size: CGSize, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let photo = fetchedAssets[indexPath.row]
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        imageManager.requestImage(for: photo, targetSize: size, contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let photoCollection = note.photoCollection else {return}
        let asset = fetchedAssets[indexPath.row]
        switch photoCollection.contains(where: {($0 as! Photo).identifier == asset.localIdentifier}) {
        case true: unlink(at: indexPath)
        case false: link(at: indexPath)
        }
    }
    
    private func link(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        //        let asset = fetchedAssets.remove(at: indexPath.row)
        //        collectionView?.deleteItems(at: [indexPath])
        let asset = fetchedAssets[indexPath.row]
        let localPhoto = Photo(context: viewContext)
        localPhoto.identifier = asset.localIdentifier
        localPhoto.createdDate = asset.creationDate
        localPhoto.modifiedDate = asset.modificationDate
        note.addToPhotoCollection(localPhoto)
        if viewContext.hasChanges {try? viewContext.save()}
        collectionView?.reloadItems(at: [indexPath])
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        guard let photoCollection = note.photoCollection else {return}
        let asset = fetchedAssets[indexPath.row]
        for photo in photoCollection {
            guard let photo = photo as? Photo else {return}
            if photo.identifier == asset.localIdentifier {
                note.removeFromPhotoCollection(photo)
                break
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
        collectionView?.reloadItems(at: [indexPath])
    }
    
}

