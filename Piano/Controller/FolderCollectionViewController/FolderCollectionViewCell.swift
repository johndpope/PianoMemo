//
//  FolderCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class FolderCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    weak var folderCollectionVC: FolderCollectionViewController?
    
    var folder: FolderCollectionViewController.Folder? {
        didSet {
            guard let folder = folder else { return }
            nameLabel.text = folder.name
            countLabel.text = "\(folder.count)"
        }
    }
    
    
    
    @IBAction func tapMore(_ sender: Any) {
        print("more")
    }
}
