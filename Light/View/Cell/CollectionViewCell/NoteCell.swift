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
        return EdgeInsets(top: 8, left: 8, bottom: 100, right: 8)
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
        viewController.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
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
    let viewController: ViewController?
    
    init(note: Note, originNoteForMerge: Note?, viewController: ViewController? = nil) {
        self.note = note
        self.originNoteForMerge = originNoteForMerge
        self.viewController = viewController
    }
}

class NoteCell: UICollectionViewCell, ViewModelAcceptable {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var mergeButton: UIButton!
    @IBOutlet weak var shareLabel: UILabel!
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    
    var viewModel: ViewModel? {
        didSet {
            backgroundColor = Color.white
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
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // 1
        if recognizer.state == .began {
            backgroundColor = Color.white
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        // 2
        if recognizer.state == .changed {
            let translation = recognizer.translation(in: self)
            center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)
            // has the user dragged the item far enough to initiate a delete/complete?
            deleteOnDragRelease = abs(frame.origin.x) > frame.size.width / 3.0
            
            // fade the contextual clues
            let cueAlpha = abs(frame.origin.x) / (frame.size.width / 3.0)
            // indicate when the user has pulled the item far enough to invoke the given action
            backgroundColor = Color(hex6: "FF2D55").withAlphaComponent(cueAlpha)
            
        }
        // 3
        if recognizer.state == .ended {
            View.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.backgroundColor = Color.white
            }
            
            // the frame this cell had before user dragged it
            let originalFrame = CGRect(x: 8, y: frame.origin.y,
                                       width: bounds.size.width, height: bounds.size.height)
            if !deleteOnDragRelease {
                // if the item is not being deleted, snap back to the original location
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.frame = originalFrame
                })
            }
            
            if deleteOnDragRelease {
                guard let noteViewModel = viewModel as? NoteViewModel,
                    let vc = noteViewModel.viewController,
                    let context = noteViewModel.note.managedObjectContext else { return }
                context.performAndWait {
                    if vc is TrashCollectionViewController {
                        context.delete(noteViewModel.note)
                        (vc.navigationController as? TransParentNavigationController)?.show(message: "✨메모가 완전히 삭제되었습니다.".loc)
                    } else {
                        noteViewModel.note.isInTrash = true
                        (vc.navigationController as? TransParentNavigationController)?.show(message: "✨휴지통에서 메모를 복구할 수 있어요✨".loc)
                    }
                    
                    context.saveIfNeeded()
                }
                
                
            }
            
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: superview!)
            if abs(translation.x) > abs(translation.y) {
                return true
            }
            return false
        }
        return false
    }
    
    
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
//        view.cornerRadius = 15
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
            
            noteViewModel.viewController?.transparentNavigationController?.show(message: "합치기 성공✨")
        }
        
    }
    
}

extension NoteCell: UIGestureRecognizerDelegate {
    
}
