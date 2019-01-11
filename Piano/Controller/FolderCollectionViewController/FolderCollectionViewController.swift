//
//  FolderCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit


class FolderCollectionViewController: UICollectionViewController {
    
    struct Folder {
        let name: String
        let count: Int
    }
    
    var dataSource: [[Folder]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //section1
        let folder1 = Folder(name: "모든 메모", count: 24)
        let folder2 = Folder(name: "잠긴 메모", count: 3)
        let folder3 = Folder(name: "삭제된 메모", count: 3)
        dataSource.append([folder1, folder2, folder3])
        
        //section2
        let folder4 = Folder(name: "😍", count: 10)
        let folder5 = Folder(name: "👨‍💻", count: 5)
        let folder6 = Folder(name: "👿", count: 6)
        dataSource.append([folder4, folder5, folder6])
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return dataSource.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return dataSource[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCollectionViewCell.reuseIdentifier, for: indexPath) as? FolderCollectionViewCell else { return UICollectionViewCell() }
        
        cell.folder = dataSource[indexPath.section][indexPath.item]
        cell.folderCollectionVC = self
        
        cell.moreButton.isHidden = indexPath.section == 0
    
        // Configure the cell
    
        return cell
    }

}
