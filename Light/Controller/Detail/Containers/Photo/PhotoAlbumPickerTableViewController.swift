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
    var asset: PHAsset
    var image: UIImage?
    var title: String
    var count: Int
}

/// 보여주고자 하는 Local Album 저장소 목록.
let PHAssetFetchTypes: [PHAssetCollectionSubtype] = [.smartAlbumRecentlyAdded, .smartAlbumUserLibrary,
                                                     .smartAlbumSelfPortraits, .smartAlbumPanoramas,
                                                     .smartAlbumScreenshots]

class PhotoAlbumPickerTableViewController: UITableViewController {
    
    weak var photoPickerVC: PhotoPickerCollectionViewController?
    
    private let imageManager = PHCachingImageManager()
    private var fetchedAlbums = [AlbumInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetch()
    }
    
}

extension PhotoAlbumPickerTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.requestAlbum()
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    func requestAlbum() {
        for type in PHAssetFetchTypes {
            if let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                   subtype: type, options: nil).firstObject {
                fetchAlbum(assets: album)
            }
        }
        // 네이버 클라우드와 같은 외부 폴더
        let externalAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        guard externalAlbums.count > 0 else {return}
        for externalAlbum in externalAlbums.objects(at: IndexSet(0...externalAlbums.count - 1)) {
            fetchAlbum(assets: externalAlbum)
        }
    }
    
    private func fetchAlbum(assets: PHAssetCollection) {
        let albumAssets = PHAsset.fetchAssets(in: assets, options: nil)
        guard albumAssets.count > 0, let asset = albumAssets.lastObject else {return}
        fetchedAlbums.append(AlbumInfo(type: assets.assetCollectionType, subType: assets.assetCollectionSubtype,
                                       asset: asset, image: nil, title: assets.localizedTitle ?? "",
                                       count: albumAssets.count))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedAlbums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoAlbumTableViewCell") as! PhotoAlbumTableViewCell
        if fetchedAlbums[indexPath.row].image != nil {
            cell.configure(album: fetchedAlbums[indexPath.row])
        } else {
            requestImage(indexPath) { (image, error) in
                self.fetchedAlbums[indexPath.row].image = image
                cell.configure(album: self.fetchedAlbums[indexPath.row])
            }
        }
        return cell
    }
    
    private func requestImage(_ indexPath: IndexPath, _ completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let asset = fetchedAlbums[indexPath.row].asset
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMinimumSize,
                                  contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        requestAlbumPhoto(at: indexPath)
    }
    
    private func requestAlbumPhoto(at indexPath: IndexPath) {
        DispatchQueue.global().async {
            self.fetchAlbumPhoto(from: self.fetchedAlbums[indexPath.row])
            DispatchQueue.main.async { [weak self] in
                self?.photoPickerVC?.collectionView?.reloadData()
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func fetchAlbumPhoto(from albumInfo: AlbumInfo) {
        if albumInfo.type.rawValue == 1 { // 네이버 클라우드와 같은 외부 폴더
            let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            for album in albums.objects(at: IndexSet(0...albums.count - 1)) where album.localizedTitle == albumInfo.title {
                photoPickerVC?.photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                photoPickerVC?.currentAlbumTitle = album.localizedTitle ?? ""
            }
        } else {
            if let album = PHAssetCollection.fetchAssetCollections(with: albumInfo.type,
                                                                   subtype: albumInfo.subType, options: nil).firstObject {
                photoPickerVC?.photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                photoPickerVC?.currentAlbumTitle = album.localizedTitle ?? ""
            }
        }
        guard let photoFetchResult = photoPickerVC?.photoFetchResult else {return}
        photoPickerVC?.fetchedAssets.removeAll()
        photoFetchResult.objects(at: IndexSet(0...photoFetchResult.count - 1)).reversed().forEach {
            photoPickerVC?.fetchedAssets.append(PhotoInfo(asset: $0, image: nil))
        }
    }
    
}
