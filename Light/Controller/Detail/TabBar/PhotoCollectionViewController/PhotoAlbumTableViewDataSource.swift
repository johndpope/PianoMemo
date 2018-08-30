//
//  PhotoPickerAlbumTableViewDataSource.swift
//  Light
//
//  Created by JangDoRi on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

/// 앨범 정보.
struct AlbumInfo {
    var type: PHAssetCollectionType
    var subType: PHAssetCollectionSubtype
    var image: UIImage!
    var title: String
    var count: Int
}


