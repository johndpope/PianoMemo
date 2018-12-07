//
//  AttachTagCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 03/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class AttachTagViewController: UIViewController {
    var note: Note!
    weak var storageService: StorageService!
    var button: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleButton: UIButton!
    
    var dataSource: [String] {
        return storageService.local.emojiTags
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleButton.setTitle(note.tags, for: .normal)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        button = nil
    }
    
    @IBAction func tapDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

extension AttachTagViewController: UICollectionViewDataSource {
   
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachTagCell.reuseIdentifier, for: indexPath) as! AttachTagCell
        let emoji = dataSource[indexPath.item]
        let noteTags = note.tags ?? ""
        cell.emojiLabel.text = emoji
        cell.addImageView.image = noteTags.contains(emoji) ? #imageLiteral(resourceName: "deleteTag") : #imageLiteral(resourceName: "add")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
        return view
    }
}

extension AttachTagViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //이모지가 없으면 추가, 있으면 제거, 이미지 바꾸기
        let cell = collectionView.cellForItem(at: indexPath) as! AttachTagCell
        
        let emoji = dataSource[indexPath.item]
        var noteTags = note.tags ?? ""
        
        let containsEmoji = noteTags.contains(emoji)
        
        if containsEmoji {
            //제거한다.
            noteTags.removeCharacters(strings: [emoji])
            storageService.local.update(note: note, tags: noteTags)
            cell.addImageView.image = #imageLiteral(resourceName: "add")
            
            if noteTags.count != 0 {
                titleButton.setTitle(noteTags, for: .normal)
                button.setTitle(noteTags, for: .normal)
                titleButton.setImage(nil, for: .normal)
                button.setImage(nil, for: .normal)
            } else {
                titleButton.setTitle(nil, for: .normal)
                button.setTitle(nil, for: .normal)
                titleButton.setImage(#imageLiteral(resourceName: "defaultTagIcon"), for: .normal)
                button.setImage(#imageLiteral(resourceName: "defaultTagIcon"), for: .normal)
            }
            
        } else {
            //더한다.
            noteTags.append(emoji)
            storageService.local.update(note: note, tags: noteTags)
            cell.addImageView.image = #imageLiteral(resourceName: "deleteTag")
            if noteTags.count != 0 {
                titleButton.setTitle(noteTags, for: .normal)
                button.setTitle(noteTags, for: .normal)
                titleButton.setImage(nil, for: .normal)
                button.setImage(nil, for: .normal)
            } else {
                titleButton.setTitle(nil, for: .normal)
                button.setTitle(nil, for: .normal)
                titleButton.setImage(#imageLiteral(resourceName: "defaultTagIcon"), for: .normal)
                button.setImage(#imageLiteral(resourceName: "defaultTagIcon"), for: .normal)
            }
        }
        
    }
}


extension AttachTagViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
