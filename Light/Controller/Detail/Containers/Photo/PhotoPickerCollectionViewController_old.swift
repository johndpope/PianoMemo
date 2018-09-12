////
////  PhotoPickerCollectionViewController.swift
////  Light
////
////  Created by Kevin Kim on 2018. 9. 3..
////  Copyright © 2018년 Piano. All rights reserved.
////

import UIKit
import Photos


//class PhotoPickerCollectionViewController: UICollectionViewController, Notable {
//    var note: Note!
//    @IBOutlet weak var albumButton: UIButton!
//    
//    weak var photoVC: PhotoCollectionViewController?
//    
//    private var note: Note? {
//        return (navigationController?.parent as? DetailViewController)?.note
//    }
//    private let imageManager = PHCachingImageManager()
//    
//    var photoFetchResult = PHFetchResult<PHAsset>()
//    var fetchedAssets = [PhotoInfo]()
//    var currentAlbumTitle = "" {
//        didSet {
//            guard !currentAlbumTitle.isEmpty else {return}
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                self.navigationItem.rightBarButtonItem?.title = self.currentAlbumTitle
//            }
//        }
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        collectionView?.allowsSelection = true
//        fetch()
//    }
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "PhotoAlbumPickerTableViewController" {
//            guard let albumPickerVC = segue.destination as? PhotoAlbumPickerTableViewController else {return}
//            albumPickerVC.photoPickerVC = self
//        } else if segue.identifier == "PhotoDetailViewController" {
//            guard let photoDetailVC = segue.destination as? PhotoDetailViewController else {return}
//            if let image = sender as? UIImage {
//                photoDetailVC.image = image
//            } else if let asset = sender as? PHAsset {
//                photoDetailVC.asset = asset
//            }
//        }
//    }
//    
//}
//
//extension PhotoPickerCollectionViewController {
//    
//    private func fetch() {
//        DispatchQueue.global().async {
//            self.request()
//        }
//    }
//    
//    private func request() {
//        guard let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary,
//                                                                  options: nil).firstObject else {return}
//        currentAlbumTitle = album.localizedTitle ?? ""
//        photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
//        let indexSet = IndexSet(0...photoFetchResult.count - 1)
//        fetchedAssets = photoFetchResult.objects(at: indexSet).reversed().map {PhotoInfo(asset: $0, image: nil)}
//        DispatchQueue.main.async { [weak self] in
//            self?.collectionView?.reloadData()
//        }
//    }
//    
//}
//
//extension PhotoPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
//    
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return fetchedAssets.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
//            return CGSize(width: collectionView.bounds.height, height: collectionView.bounds.height)
//        }
//        var portCellNum: CGFloat = 3
//        var landCellNum: CGFloat = 5
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            portCellNum = portCellNum * 2
//            landCellNum = landCellNum * 2
//        }
//        let portCutSpacing = flowLayout.minimumInteritemSpacing * (portCellNum - 1)
//        let landCutSpacing = flowLayout.minimumInteritemSpacing * (landCellNum - 1)
//        var cellSize = collectionView.bounds.height
//        if flowLayout.scrollDirection == .vertical {
//            cellSize = floor((collectionView.bounds.width - portCutSpacing) / portCellNum)
//            if UIApplication.shared.statusBarOrientation.isLandscape {
//                cellSize = floor((collectionView.bounds.width - landCutSpacing) / landCellNum)
//            }
//        }
//        return CGSize(width: cellSize, height: cellSize)
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
//        cell.linkImageView.image = #imageLiteral(resourceName: "unLink")
//        if let image = fetchedAssets[indexPath.row].image {
//            cell.configure(image)
//            selection(cell, indexPath)
//        } else {
//            requestImage(indexPath, size: PHImageManagerMinimumSize) { (image, error) in
//                self.fetchedAssets[indexPath.row].image = image
//                cell.configure(image)
//                self.selection(cell, indexPath)
//            }
//        }
//        cell.cellDidSelected = {
//            self.collectionView(collectionView, didSelectItemAt: indexPath)
//        }
//        cell.contentDidSelected = {
//            self.open(with: indexPath)
//        }
//        return cell
//    }
//    
//    private func requestImage(_ indexPath: IndexPath, size: CGSize, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
//        guard indexPath.row < fetchedAssets.count else {return}
//        let asset = fetchedAssets[indexPath.row].asset
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        imageManager.requestImage(for: asset, targetSize: size,
//                                  contentMode: .aspectFit, options: options, resultHandler: completion)
//    }
//    
//    private func selection(_ cell: PhotoCollectionViewCell, _ indexPath: IndexPath) {
//        guard let photoCollection = note?.photoCollection else {return}
//        let targetAsset = fetchedAssets[indexPath.row].asset
//        switch photoCollection.contains(where: {($0 as! Photo).identifier == targetAsset.localIdentifier}) {
//        case true: cell.linkImageView.image = #imageLiteral(resourceName: "linked")
//        case false: cell.linkImageView.image = #imageLiteral(resourceName: "unLink")
//        }
//    }
//    
//    private func open(with indexPath: IndexPath) {
//        requestImage(indexPath, size: PHImageManagerMaximumSize) { (image, error) in
//            let data: Any? = (image != nil) ? image : self.fetchedAssets[indexPath.row]
//            self.performSegue(withIdentifier: "PhotoDetailViewController", sender: data)
//        }
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        manageLink(indexPath)
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        manageLink(indexPath)
//    }
//    
//    private func manageLink(_ indexPath: IndexPath) {
//        guard let note = note, let viewContext = note.managedObjectContext else {return}
//        guard let photoCollection = note.photoCollection else {return}
//        let selectedAsset = fetchedAssets[indexPath.row].asset
//        switch photoCollection.contains(where: {($0 as! Photo).identifier == selectedAsset.localIdentifier}) {
//        case true:
//            for localPhoto in photoCollection {
//                guard let localPhoto = localPhoto as? Photo else {continue}
//                guard  localPhoto.identifier == selectedAsset.localIdentifier else {continue}
//                note.removeFromPhotoCollection(localPhoto)
//                break
//            }
//        case false:
//            let localPhoto = Photo(context: viewContext)
//            localPhoto.identifier = selectedAsset.localIdentifier
//            note.addToPhotoCollection(localPhoto)
//        }
//        if viewContext.hasChanges {
//            try? viewContext.save()
//            photoVC?.isNeedFetch = true
//            UIView.performWithoutAnimation {
//                self.collectionView?.reloadItems(at: [indexPath])
//            }
//        }
//    }
//    
//}
