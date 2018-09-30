//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 20..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension Note: Collectionable {
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets(top: 0, left: 8, bottom: 100, right: 8)
    }
    
    internal func size(view: View) -> CGSize {
        let width = view.bounds.width
        let headHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let dateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = minimumInteritemSpacing
        let spacing: CGFloat = 4
        let totalHeight = headHeight + dateHeight + margin * 2 + spacing
        var cellCount: CGFloat = 3
        if width > 414 {
            let widthOne = (width - (cellCount + 1) * margin) / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = (width - (cellCount + 1) * margin) / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        cellCount = 1
        return CGSize(width: (width - (cellCount + 1) * margin), height: totalHeight)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        guard let mainVC = viewController as? MainViewController else { return }
        
        if collectionView.allowsMultipleSelection {
            mainVC.navigationItem.leftBarButtonItem?.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0 ) != 0
            
        } else {
            mainVC.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
        }
    }
    
    func didDeselectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        if collectionView.allowsMultipleSelection {
            viewController.navigationItem.leftBarButtonItem?.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0 ) != 0
        }
    }
}

struct NoteViewModel: ViewModel {
    let note: Note
    let originNoteForMerge: Note?
    
    init(note: Note, originNoteForMerge: Note?) {
        self.note = note
        self.originNoteForMerge = originNoteForMerge
    }
}

class NoteCell: UICollectionViewCell, ViewModelAcceptable {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var mergeButton: UIButton!
    @IBOutlet weak var shareLabel: UILabel!
    
    var viewModel: ViewModel? {
        didSet {
            guard let noteViewModel = self.viewModel as? NoteViewModel else { return }
            let note = noteViewModel.note
            mergeButton.isHidden = noteViewModel.originNoteForMerge == nil

            if let date = note.modifiedDate {
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                if Calendar.current.isDateInToday(date) {
                    dateLabel.textColor = Color.point
                } else {
                    dateLabel.textColor = Color.lightGray
                }
            }
            
            titleLabel.text = note.title
            shareLabel.isHidden = note.record()?.share == nil
            
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        view.cornerRadius = 15
        return view
    }

    @IBAction func merge(_ sender: Any) {
        guard let noteViewModel = viewModel as? NoteViewModel,
            let originNoteForMerge = noteViewModel.originNoteForMerge,
            let context = originNoteForMerge.managedObjectContext  else { return }
        let note = noteViewModel.note
        
        let originContent = originNoteForMerge.content ?? ""
        let selectedContent = note.content ?? ""
        
        originNoteForMerge.content = originContent + "\n" + selectedContent
        originNoteForMerge.modifiedDate = Date()
        originNoteForMerge.hasEdit = true
        
        context.performAndWait {
            context.delete(note)
            context.saveIfNeeded()
        }
        
    }
    
}
