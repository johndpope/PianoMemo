//
//  PhotoAlbumPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 4..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

/// 앨범 정보.
struct AlbumInfo {
    var type: PHAssetCollectionType
    var subType: PHAssetCollectionSubtype
    var photo: PHAsset
    var image: UIImage?
    var title: String
    var count: Int
}

class PhotoAlbumPickerTableViewController: UITableViewController {
    
    // 보여주고자 하는 Local Album 저장소 목록.
    private let subTypes: [PHAssetCollectionSubtype] = [.smartAlbumRecentlyAdded, .smartAlbumUserLibrary,
                                                        .smartAlbumSelfPortraits, .smartAlbumPanoramas,
                                                        .smartAlbumScreenshots]
    
    weak var photoPickerCollectionVC: PhotoPickerCollectionViewController?
    
    private let imageManager = PHCachingImageManager()
    private var albumAssets = [AlbumInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetch()
    }
    
    private func fetch() {
        DispatchQueue.global().async {
            self.requestAlbum()
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
}

extension PhotoAlbumPickerTableViewController {
    
    func requestAlbum() {
        for type in subTypes {
            if let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: type, options: nil).firstObject {
                fetchAlbum(asset: album)
            }
        }
        // 네이버 클라우드와 같은 외부 폴더
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        guard albums.count > 0 else {return}
        for album in albums.objects(at: IndexSet(0...albums.count - 1)) {
            fetchAlbum(asset: album)
        }
    }
    
    private func fetchAlbum(asset: PHAssetCollection) {
        let albumPhotos = PHAsset.fetchAssets(in: asset, options: nil)
        guard albumPhotos.count > 0, let photo = albumPhotos.lastObject else {return}
        albumAssets.append(AlbumInfo(type: asset.assetCollectionType, subType: asset.assetCollectionSubtype,
                                     photo: photo, image: nil, title: asset.localizedTitle ?? "",
                                     count: albumPhotos.count))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumAssets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoAlbumTableViewCell") as! PhotoAlbumTableViewCell
        if albumAssets[indexPath.row].image != nil {
            cell.configure(album: albumAssets[indexPath.row])
        } else {
            requestImage(indexPath) { (image, error) in
                self.albumAssets[indexPath.row].image = image
                cell.configure(album: self.albumAssets[indexPath.row])
            }
        }
        return cell
    }
    
    private func requestImage(_ indexPath: IndexPath, _ completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let photo = albumAssets[indexPath.row].photo
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        imageManager.requestImage(for: photo, targetSize: PHImageManagerMinimumSize, contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        requestAlbumPhoto(at: indexPath)
        navigationController?.popViewController(animated: true)
    }
    
    private func requestAlbumPhoto(at indexPath: IndexPath) {
        DispatchQueue.global().async {
            self.fetchAlbumPhoto(from: self.albumAssets[indexPath.row])
            DispatchQueue.main.async { [weak self] in
                self?.photoPickerCollectionVC?.collectionView?.reloadData()
            }
        }
    }
    
    private func fetchAlbumPhoto(from albumInfo: AlbumInfo) {
        // 네이버 클라우드와 같은 외부 폴더
        if albumInfo.type.rawValue == 1 {
            let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            for album in albums.objects(at: IndexSet(0...albums.count - 1)) where album.localizedTitle == albumInfo.title {
                photoPickerCollectionVC?.photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                photoPickerCollectionVC?.currentAlbumTitle = album.localizedTitle ?? ""
            }
        } else {
            if let album = PHAssetCollection.fetchAssetCollections(with: albumInfo.type, subtype: albumInfo.subType, options: nil).firstObject {
                photoPickerCollectionVC?.photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                photoPickerCollectionVC?.currentAlbumTitle = album.localizedTitle ?? ""
            }
        }
        guard let photoFetchResult = photoPickerCollectionVC?.photoFetchResult else {return}
        let indexSet = IndexSet(0...photoFetchResult.count - 1)
        photoPickerCollectionVC?.fetchedAssets.removeAll()
        photoFetchResult.objects(at: indexSet).reversed().forEach {
            photoPickerCollectionVC?.fetchedAssets.append(PhotoInfo(photo: $0, image: nil))
        }
    }
    
}
