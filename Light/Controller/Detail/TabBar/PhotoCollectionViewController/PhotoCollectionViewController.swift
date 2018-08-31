//
//  PhotoCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

/// PHImage가 가져야하는 최소 size.
let PHImageManagerMinimumSize = CGSize(width: 125, height: 125)

class PhotoViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }
    
    private lazy var imageManager = PHCachingImageManager.default()
    private var photoFetchResult = PHFetchResult<PHAsset>()
    private var fetchedAssets = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumInteritemSpacing = 2
            flowLayout.minimumLineSpacing = 2
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "photo".loc
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem(_:)))
        auth {self.fetch()}
    }
    
    @objc private func addItem(_ button: UIBarButtonItem) {
        //        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        //        let newAct = UIAlertAction(title: "create".loc, style: .default) { _ in
        //            self.takePhoto()
        //        }
        //        let existAct = UIAlertAction(title: "import".loc, style: .default) { _ in
        //self.navigationController?.view.backgroundColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.performSegue(withIdentifier: "PhotoPickerCollectionViewController", sender: nil)
        //        }
        //        let cancelAct = UIAlertAction(title: "cencel".loc, style: .cancel)
        //        alert.addAction(newAct)
        //        alert.addAction(existAct)
        //        alert.addAction(cancelAct)
        //        present(alert, animated: true)
    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoPickerCollectionViewController" {
            guard let PhotoPVC = segue.destination as? PhotoPickerCollectionViewController else {return}
            PhotoPVC.note = note
        }
        if segue.identifier == "PhotoDetailViewController" {
            guard let PhotoDetailVC = segue.destination as? PhotoDetailViewController else {return}
            PhotoDetailVC.image = sender as? UIImage
        }
    }
    
}

extension PhotoViewController {
    
    //    private func takePhoto() {
    //
    //    }
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    private func request() {
        guard let photoCollection = note.photoCollection else {return}
        guard let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject else {return}
        photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
        let indexSet = IndexSet(0...photoFetchResult.count - 1)
        fetchedAssets = photoFetchResult.objects(at: indexSet).reversed().filter { asset in
            photoCollection.contains(where: {($0 as! Photo).identifier == asset.localIdentifier})
        }
        purge()
    }
    
    private func purge() {
        guard let viewContext = note.managedObjectContext else {return}
        guard let photoCollection = note.photoCollection else {return}
        for photo in photoCollection {
            guard let photo = photo as? Photo else {return}
            if !fetchedAssets.contains(where: {$0.localIdentifier == photo.identifier}) {
                note.removeFromPhotoCollection(photo)
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension PhotoViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        requestImage(indexPath, size: PHImageManagerMinimumSize) { (image, error) in
            cell.configure(image)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        requestImage(indexPath, size: PHImageManagerMaximumSize) { (image, error) in
            self.performSegue(withIdentifier: "PhotoDetailViewController", sender: image)
        }
    }
    
    private func requestImage(_ indexPath: IndexPath, size: CGSize, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let photo = fetchedAssets[indexPath.row]
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        imageManager.requestImage(for: photo, targetSize: size, contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
}

