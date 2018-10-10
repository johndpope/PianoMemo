//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 20..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import BiometricAuthentication

extension Note: Collectionable {
    
    var minimumLineSpacing: CGFloat { return 0 }
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
    }
    
    internal func size(view: View) -> CGSize {
        let width = view.bounds.width
        let headlineHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .headline)]).size().height
        let subheadlineHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .subheadline)]).size().height
        let dateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = minimumInteritemSpacing
        let spacing: CGFloat = 4
        let totalHeight = headlineHeight + subheadlineHeight + dateHeight + margin * 2 + spacing * 2
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
        if let content = self.content, content.contains("🔒") {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                // authentication success
                viewController.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
                return
            }) { (error) in
                
                collectionView.indexPathsForSelectedItems?.forEach {
                    collectionView.deselectItem(at: $0, animated: true)
                }
                
                Alert.warning(from: viewController, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                
                // error
                print(error.message())
            }
        } else {
            viewController.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
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
    let viewController: ViewController?
    
    init(note: Note, viewController: ViewController? = nil) {
        self.note = note
        self.viewController = viewController
    }
}

class NoteCell: UICollectionViewCell, ViewModelAcceptable {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var shareLabel: UILabel!

    weak var refreshDelegate: UIRefreshDelegate!
    weak var syncController: Synchronizable!

    var originalCenter = CGPoint()
    var deleteOnDragRelease = false, completeOnDragRelease = false
    
    var viewModel: ViewModel? {
        didSet {
            backgroundColor = Color.white
            guard let noteViewModel = self.viewModel as? NoteViewModel else { return }
            let note = noteViewModel.note

            if let date = note.modifiedAt {
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                if Calendar.current.isDateInToday(date) {
                    dateLabel.textColor = Color.point
                } else {
                    dateLabel.textColor = Color.lightGray
                }
            }
            
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            shareLabel.isHidden = !note.isShared
            
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
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 3.0
            completeOnDragRelease = frame.origin.x > frame.size.width / 3.0
            // fade the contextual clues
            let cueAlpha = frame.origin.x / (frame.size.width / 3.0)
            // indicate when the user has pulled the item far enough to invoke the given action
            if cueAlpha < 0 {
                backgroundColor = Color(hex6: "FF2D55").withAlphaComponent(abs(cueAlpha))
            } else {
                backgroundColor = Color(hex6: "4CA734").withAlphaComponent(cueAlpha)
            }
            
            
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
            
            if deleteOnDragRelease {
                guard let noteViewModel = viewModel as? NoteViewModel,
                    let vc = noteViewModel.viewController,
                    let content = noteViewModel.note.content else { return }
                
                if vc is TrashCollectionViewController {

                    if content.contains(Preference.lockStr) {

                        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: { [weak self] in
                            // authentication success
                            //                                vc.transparentNavigationController?.show(message: "📝메모가 완전히 삭제되었습니다.🌪".loc)
                            self?.syncController.purge(note: noteViewModel.note)

                        }) { (error) in
                            Alert.warning(from: vc, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to delete this note.".loc)
                        }

                    } else {
                        syncController.purge(note: noteViewModel.note)
                        //                            vc.transparentNavigationController?.show(message: "📝메모가 완전히 삭제되었습니다.🌪".loc)
                    }

                } else {
                    //잠금이 있는 경우 터치아이디 성공하면 삭제
                    if content.contains(Preference.lockStr) {
                        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: { [weak self] in
                            // authentication success
                            self?.syncController.delete(note: noteViewModel.note)
                            vc.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
                        }) { (error) in
                            Alert.warning(from: vc, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to delete this note.".loc)
                        }

                    } else {
                        self.syncController.delete(note: noteViewModel.note)
                        vc.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
                    }
                }

                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.frame = originalFrame
                })
                
                
            } else if completeOnDragRelease {
                guard let noteViewModel = viewModel as? NoteViewModel,
                    let content = noteViewModel.note.content,
                    let vc = noteViewModel.viewController else { return }

                if content.contains(Preference.lockStr) {
                    //터치아이디 성공하면 열리게 하기

                    BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                        [weak self] in
                        // authentication success
                        self?.syncController.unlockNote(noteViewModel.note)
                        vc.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc)
                    }) { (error) in
                        Alert.warning(from: vc, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    }
                } else {
                    syncController.lockNote(noteViewModel.note)
                    vc.transparentNavigationController?.show(message: "Locked🔒".loc)
                }

                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.frame = originalFrame
                })
            } else {
                // if the item is not being deleted, snap back to the original location
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.frame = originalFrame
                })
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
    
}

extension NoteCell: UIGestureRecognizerDelegate, Refreshable, SyncControllable {
    
}
