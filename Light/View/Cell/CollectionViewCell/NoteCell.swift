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
                
                Alert.warning(from: viewController, title: "인증 실패".loc, message: "이 메모를 보기 위해서는 암호를 설정하여 입력해야합니다.".loc)
                
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
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var mergeButton: UIButton!
    @IBOutlet weak var shareLabel: UILabel!
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false, completeOnDragRelease = false
    
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
            subTitleLabel.text = note.subTitle
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
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 3.0
            completeOnDragRelease = frame.origin.x > frame.size.width / 3.0
            // fade the contextual clues
            let cueAlpha = frame.origin.x / (frame.size.width / 3.0)
            // indicate when the user has pulled the item far enough to invoke the given action
            if cueAlpha < 0 {
                backgroundColor = Color(hex6: "FF2D55").withAlphaComponent(abs(cueAlpha))
            } else {
                backgroundColor = Color.point.withAlphaComponent(cueAlpha)
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
                    let content = noteViewModel.note.content,
                    let context = noteViewModel.note.managedObjectContext else { return }
                
                context.performAndWait {
                    if vc is TrashCollectionViewController {
                        
                        if content.contains(Preference.lockStr) {
                            
                            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                                // authentication success
                                context.delete(noteViewModel.note)
                                vc.transparentNavigationController?.show(message: "✨메모가 완전히 삭제되었습니다.✨".loc)
                                context.saveIfNeeded()
                            }) { (error) in
                                Alert.warning(from: vc, title: "인증 실패😭".loc, message: "이 메모를 삭제하려면 디바이스의 설정에서 암호를 켜고 입력하세요.".loc)
                            }
                            
                        } else {
                            context.delete(noteViewModel.note)
                            vc.transparentNavigationController?.show(message: "✨메모가 완전히 삭제되었습니다.✨".loc)
                            context.saveIfNeeded()
                        }
                        
                    } else {
                        //잠금이 있는 경우 터치아이디 성공하면 삭제
                        if content.contains(Preference.lockStr) {
                            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                                // authentication success
                                context.delete(noteViewModel.note)
                                vc.transparentNavigationController?.show(message: "삭제되었습니다. 🗑👆".loc, color: Color.trash)
                                context.saveIfNeeded()
                            }) { (error) in
                                Alert.warning(from: vc, title: "인증 실패".loc, message: "이 메모를 삭제하려면 설정에서 암호를 켜고 입력하세요.".loc)
                            }
                            
                        } else {
                            noteViewModel.note.isInTrash = true
                            vc.transparentNavigationController?.show(message: "휴지통에서 메모를 복구할 수 있어요 🗑👆".loc)
                            context.saveIfNeeded()
                        }
                    }
                }
                
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.frame = originalFrame
                })
                
                
            } else if completeOnDragRelease {
                guard let noteViewModel = viewModel as? NoteViewModel,
                    let vc = noteViewModel.viewController,
                    let context = noteViewModel.note.managedObjectContext else { return }
                context.performAndWait {
                    var content = noteViewModel.note.content ?? ""
                    if content.contains(Preference.lockStr) {
                        //터치아이디 성공하면 열리게 하기
                        
                        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                            // authentication success
                            content.removeCharacters(strings: [Preference.lockStr])
                            noteViewModel.note.save(from: content)
                            vc.transparentNavigationController?.show(message: "✨메모가 열렸습니다🔓".loc)
                            context.saveIfNeeded()
                        }) { (error) in
                            Alert.warning(from: vc, title: "인증 실패".loc, message: "이 메모의 잠금을 해제하려면 디바이스의 설정에서 암호를 켜고 입력하세요.".loc)
                        }
                        
                    } else {
                        noteViewModel.note.title = Preference.lockStr + (noteViewModel.note.title ?? "")
                        noteViewModel.note.content = Preference.lockStr + (noteViewModel.note.content ?? "")
                        vc.transparentNavigationController?.show(message: "메모가 잠겼습니다🔒".loc)
                        context.saveIfNeeded()
                    }
                    
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
            
            noteViewModel.viewController?.transparentNavigationController?.show(message: "합치기 성공✨".loc)
        }
        
    }
    
}

extension NoteCell: UIGestureRecognizerDelegate {
    
}
