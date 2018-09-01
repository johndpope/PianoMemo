//
//  PhotoAlbumTableViewDataSource.swift
//  Light
//
//  Created by JangDoRi on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

/// 보여주고자 하는 Local Album 저장소 목록.
let subTypes: [PHAssetCollectionSubtype] = [.smartAlbumRecentlyAdded, .smartAlbumUserLibrary,
                                            .smartAlbumSelfPortraits, .smartAlbumPanoramas,
                                            .smartAlbumScreenshots]

extension PhotoPickerCollectionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func fetchAlbum() {
        for type in subTypes {
            if let album = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: type, options: nil).firstObject {
                addAlbum(asset: album)
            }
        }
        // 네이버 클라우드와 같은 외부 폴더
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        guard albums.count > 0 else {return}
        for album in albums.objects(at: IndexSet(0...albums.count - 1)) {
            addAlbum(asset: album)
        }
    }
    
    private func addAlbum(asset: PHAssetCollection) {
        let albumPhotos = PHAsset.fetchAssets(in: asset, options: nil)
        guard albumPhotos.count > 0, let photo = albumPhotos.lastObject else {return}
        requestImage(photo) { (image, _) in
            self.albumAssets.append(AlbumInfo(type: asset.assetCollectionType, subType: asset.assetCollectionSubtype,
                                              image: image ?? nil, title: asset.localizedTitle ?? "", count: albumPhotos.count))
        }
    }
    
    private func requestImage(_ asset: PHAsset, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMinimumSize, contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumAssets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoAlbumTableViewCell") as! PhotoAlbumTableViewCell
        cell.configure(album: albumAssets[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        requestAlbumPhoto(at: indexPath)
    }
    
    private func requestAlbumPhoto(at indexPath: IndexPath) {
        DispatchQueue.global().async {
            self.fetchAlbumPhoto(from: self.albumAssets[indexPath.row])
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.collectionView.reloadData()
                self.updateTitle()
                self.action(title: self.titleButton)
            }
        }
    }
    
    private func fetchAlbumPhoto(from albumInfo: AlbumInfo) {
        // 네이버 클라우드와 같은 외부 폴더
        if albumInfo.type.rawValue == 1 {
            let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            for album in albums.objects(at: IndexSet(0...albums.count - 1)) where album.localizedTitle == albumInfo.title {
                photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                currentAlbumTitle = album.localizedTitle ?? ""
            }
        } else {
            if let album = PHAssetCollection.fetchAssetCollections(with: albumInfo.type, subtype: albumInfo.subType, options: nil).firstObject {
                photoFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                currentAlbumTitle = album.localizedTitle ?? ""
            }
        }
        let indexSet = IndexSet(0...photoFetchResult.count - 1)
        fetchedAssets = photoFetchResult.objects(at: indexSet).reversed()
    }
    
}
