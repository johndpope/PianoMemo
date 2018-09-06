//
//  PhotoCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

/// 사진이 가져야 하는 최소 size.
let PHImageManagerMinimumSize = CGSize(width: 125, height: 125)

/// 사진 정보.
struct PhotoInfo {
    var asset: PHAsset
    var image: UIImage?
}

class PhotoCollectionViewController: UICollectionViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private lazy var imageManager = PHCachingImageManager.default()
    private var fetchedAssets = [PhotoInfo]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        auth {self.fetch()}
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoDetailViewController" {
            guard let photoDetailVC = segue.destination as? PhotoDetailViewController else {return}
            if let image = sender as? UIImage {
                photoDetailVC.image = image
            } else if let asset = sender as? PHAsset {
                photoDetailVC.asset = asset
            }
        }
    }
    
}

extension PhotoCollectionViewController: ContainerDatasource {
    
    internal func reset() {
        
    }
    
    internal func startFetch() {
        
    }
    
}

extension PhotoCollectionViewController {
    
    private func auth(_ completion: @escaping (() -> ())) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized: completion()
                default: self.alert()
                }
            }
        }
    }
    
    private func alert() {
        let alert = UIAlertController(title: nil, message: "permission_photo".loc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
    }
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        guard let photoCollection = note?.photoCollection else {return}
        fetchedAssets.removeAll()
        let photoCollectionIDs = photoCollection.map {($0 as! Photo).identifier!}
        if !photoCollectionIDs.isEmpty {
            let photoFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: photoCollectionIDs, options: nil)
            var tempFetchedAssets = [PhotoInfo]()
            for asset in photoFetchResult.objects(at: IndexSet(0...photoFetchResult.count - 1)) {
                tempFetchedAssets.append(PhotoInfo(asset: asset, image: nil))
            }
            for id in photoCollectionIDs {
                guard let photoInfo = tempFetchedAssets.first(where: {$0.asset.localIdentifier == id}) else {continue}
                fetchedAssets.append(photoInfo)
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
        }
        purge()
    }
    
    private func purge() {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let photoCollection = note.photoCollection else {return}
        var notePhotosToDelete: [Photo] = []
        for localPhoto in photoCollection {
            guard let localPhoto = localPhoto as? Photo, let id = localPhoto.identifier else {continue}
            if PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).count == 0 {
                notePhotosToDelete.append(localPhoto)
            }
        }
        notePhotosToDelete.forEach {viewContext.delete($0)}
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
        if let image = fetchedAssets[indexPath.row].image {
            cell.configure(image)
        } else {
            requestImage(indexPath, size: PHImageManagerMinimumSize) { (image, error) in
                self.fetchedAssets[indexPath.row].image = image
                cell.configure(image)
            }
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        requestImage(indexPath, size: PHImageManagerMaximumSize) { (image, error) in
            let data: Any? = (image != nil) ? image : self.fetchedAssets[indexPath.row]
            self.performSegue(withIdentifier: "PhotoDetailViewController", sender: data)
        }
    }
    
    private func requestImage(_ indexPath: IndexPath, size: CGSize, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        guard indexPath.row < fetchedAssets.count else {return}
        let asset = fetchedAssets[indexPath.row].asset
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        imageManager.requestImage(for: asset, targetSize: size,
                                  contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
}
