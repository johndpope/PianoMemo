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
    var image: UIImage!
    var title: String
    var count: Int
}

class PhotoAlbumPickerTableViewController: UITableViewController {

    var albumAssets = [AlbumInfo]()
    // 보여주고자 하는 Local Album 저장소 목록.
    let subTypes: [PHAssetCollectionSubtype] = [.smartAlbumRecentlyAdded, .smartAlbumUserLibrary,
                                                .smartAlbumSelfPortraits, .smartAlbumPanoramas,
                                                .smartAlbumScreenshots]

    weak var photoPickerCollectionVC: PhotoPickerCollectionViewController?



    override func viewDidLoad() {
        super.viewDidLoad()

    }

    private func fetch() {
        DispatchQueue.global().async {
//            self.fetchAlbum()
        }
    }


}

extension PhotoAlbumPickerTableViewController {
    
    
//    func fetchAlbum() {
//        for type in subTypes {
//            if let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: type, options: nil).firstObject {
//                addAlbum(asset: album)
//            }
//        }
//        // 네이버 클라우드와 같은 외부 폴더
//        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
//        guard albums.count > 0 else {return}
//        for album in albums.objects(at: IndexSet(0...albums.count - 1)) {
//            addAlbum(asset: album)
//        }
//    }
//
//    private func addAlbum(asset: PHAssetCollection) {
//        let albumPhotos = PHAsset.fetchAssets(in: asset, options: nil)
//        guard albumPhotos.count > 0 else {return}
//        albumAssets.append(AlbumInfo(type: asset.assetCollectionType, subType: asset.assetCollectionSubtype, image: nil, title: asset.localizedTitle ?? "", count: albumPhotos.count))
//
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return albumAssets.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoAlbumTableViewCell") as! PhotoAlbumTableViewCell
//        if albumAssets[indexPath.row].image != nil {
//            print("앨범 reuse", indexPath)
//            cell.configure(album: albumAssets[indexPath.row])
//        } else {
//            requestImage(indexPath) { (image, error) in
//                self.albumAssets[indexPath.row].image = image
//                cell.configure(album: self.albumAssets[indexPath.row])
//            }
//        }
//        return cell
//    }
//
//    private func requestImage(_ indexPath: IndexPath, _ completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
//        let photo = albumAssets[indexPath.row]
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        imageManager.requestImage(for: <#T##PHAsset#>, targetSize: <#T##CGSize#>, contentMode: <#T##PHImageContentMode#>, options: <#T##PHImageRequestOptions?#>, resultHandler: <#T##(UIImage?, [AnyHashable : Any]?) -> Void#>)
//        imageManager.requestImage(for: photo, targetSize: PHImageManagerMinimumSize, contentMode: .aspectFit, options: options, resultHandler: completion)
//    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: false)
//        requestAlbumPhoto(at: indexPath)
//    }
//
//    private func requestAlbumPhoto(at indexPath: IndexPath) {
//        DispatchQueue.global().async {
//            self.fetchAlbumPhoto(from: self.albumAssets[indexPath.row])
//            DispatchQueue.main.async { [weak self] in
//                self?.collectionView?.reloadData()
//            }
//        }
//    }
//
//    private func fetchAlbumPhoto(from albumInfo: AlbumInfo) {
//        // 네이버 클라우드와 같은 외부 폴더
//        if albumInfo.type.rawValue == 1 {
//            let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
//            for album in albums.objects(at: IndexSet(0...albums.count - 1)) where album.localizedTitle == albumInfo.title {
//                photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
//                currentAlbumTitle = album.localizedTitle ?? ""
//            }
//        } else {
//            if let album = PHAssetCollection.fetchAssetCollections(with: albumInfo.type, subtype: albumInfo.subType, options: nil).firstObject {
//                photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
//                currentAlbumTitle = album.localizedTitle ?? ""
//            }
//        }
//        let indexSet = IndexSet(0...photoFetchResult.count - 1)
//        fetchedAssets.removeAll()
//        photoFetchResult.objects(at: indexSet).reversed().forEach {
//            fetchedAssets.append(PhotoInfo(photo: $0, image: nil))
//        }
//    }
}
