//
//  PhotoCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

let PHImageManagerMinimumSize = CGSize(width: 125, height: 125)

/// 사진 정보.
struct PhotoInfo {
    var photo: PHAsset
    var image: UIImage?
}

class PhotoCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ContainerDatasource {
    
    var note: Note? {
        get {
            return (navigationController?.parent as? DetailViewController)?.note
        } set {
            (navigationController?.parent as? DetailViewController)?.note = newValue
        }
    }
    
    private lazy var imageManager = PHCachingImageManager.default()
    private var photoFetchResult = PHFetchResult<PHAsset>()
    private var fetchedAssets = [PhotoInfo]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        auth {self.fetch()}
    }
    
    internal func reset() {
        fetchedAssets = []
        collectionView?.reloadData()
    }
    
    internal func startFetch() {
        //auth {self.fetch()}
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoDetailViewController" {
            guard let PhotoDetailVC = segue.destination as? PhotoDetailViewController else {return}
            if let image = sender as? UIImage {
                PhotoDetailVC.image = image
            } else {
                PhotoDetailVC.asset = sender as? PHAsset
            }
        }
    }
    
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
        if fetchedAssets[indexPath.row].image != nil {
            cell.configure(fetchedAssets[indexPath.row].image)
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
            self.performSegue(withIdentifier: "PhotoDetailViewController", sender: (image != nil) ? image : self.fetchedAssets[indexPath.row])
        }
    }
    
    private func requestImage(_ indexPath: IndexPath, size: CGSize, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let photo = fetchedAssets[indexPath.row].photo
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        imageManager.requestImage(for: photo, targetSize: size, contentMode: .aspectFit, options: options, resultHandler: completion)
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
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    private func request() {
        guard let photoCollection = note?.photoCollection else {return}
        let localIDs = photoCollection.map {($0 as! Photo).identifier!}
        guard !localIDs.isEmpty else {return}
        photoFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: localIDs, options: nil)
        let indexSet = IndexSet(0...photoFetchResult.count - 1)
        fetchedAssets.removeAll()
        photoFetchResult.objects(at: indexSet).reversed().forEach {
            fetchedAssets.append(PhotoInfo(photo: $0, image: nil))
        }
        purge()
    }
    
    private func purge() {
        guard let note = note,
            let viewContext = note.managedObjectContext else {return}
        guard let photoCollection = note.photoCollection else {return}
        for photo in photoCollection {
            guard let photo = photo as? Photo else {return}
            if !fetchedAssets.contains(where: {$0.photo.localIdentifier == photo.identifier}) {
                note.removeFromPhotoCollection(photo)
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
