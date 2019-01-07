//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 06/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var emojiTagLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var note: Note? {
        didSet {
            guard let note = note else { return }
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            emojiTagLabel.text = note.tags
            let date = note.modifiedAt as Date? ?? Date()
            dateLabel.text = DateFormatter.sharedInstance.string(from: date)
        }
    }
    weak var noteCollectionVC: NoteCollectionViewController?
    

    lazy var customSelectedBackgroudView: UIView = {
        let view = UIView()
        view.backgroundColor = Color(red: 153/255, green: 199/255, blue: 255/255, alpha: 0.3)
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(tapLongPress(_:)))
        self.addGestureRecognizer(longPress)
        
        
    }
    
    @IBAction func tapLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            noteCollectionVC?.setEditingVC(editing: true)
            
            guard let vc = noteCollectionVC,
                let indexPath = vc.collectionView.indexPath(for: self) else { return }
            vc.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .left)
            vc.setToolbarBtnsEnabled()
        }
    }
}
