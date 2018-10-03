//
//  DetailVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import ContactsUI
import CoreLocation

protocol ContainerDatasource {
    func reset()
    func startFetch()
    
}

extension DetailViewController {

    internal func setNavigationItems(state: VCState){
        var btns: [BarButtonItem] = []
        
        switch state {
        case .normal:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = false
            completionToolbar.isHidden = true
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            let redo = BarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .plain, target: self, action: #selector(redo(_:)))
            if let undoManager = textView.undoManager {
                redo.isEnabled = undoManager.canRedo
            }
            btns.append(redo)
            let undo = BarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .plain, target: self, action: #selector(undo(_:)))
            if let undoManager = textView.undoManager {
                undo.isEnabled = undoManager.canUndo
            }
            btns.append(undo)
            
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = self.state != .merge ? false : true
            completionToolbar.isHidden = true
        case .piano:
            
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                navigationItem.titleView = titleView
            }
            
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            defaultToolbar.isHidden = true
            completionToolbar.isHidden = false
        case .merge:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = true
            completionToolbar.isHidden = true
            
        case .trash:
            let restore = BarButtonItem(title: "복원".loc, style: .plain, target: self, action: #selector(restore(_:)))
            btns.append(restore)
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = true
            completionToolbar.isHidden = true
        }
        
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
//    internal func setShareImage() {
//        if note.record()?.share != nil {
//            shareItem.image = #imageLiteral(resourceName: "addPeople2")
//        } else {
//            shareItem.image = #imageLiteral(resourceName: "addPeople")
//        }
//    }
    
    @IBAction func restore(_ sender: Any) {
        guard let context = note.managedObjectContext else { return }
        
        context.performAndWait {
            note.isInTrash = false
            note.modifiedDate = Date()
            context.saveIfNeeded()
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func highlight(_ sender: Any) {
        Feedback.success()
        setupForPiano()
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let item = sender as? UIBarButtonItem else {return}
        if note.record()?.share == nil {
            cloudManager?.share.operate(target: self, pop: item, note: self.note, thumbnail: textView, title: "텍스트".loc)
        } else {
            cloudManager?.share.configure(target: self, pop: item, note: self.note)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        Feedback.success()
        view.endEditing(true)
    }
    
    @IBAction func undo(_ sender: UIBarButtonItem) {
        guard let undoManager = textView.undoManager else { return }
        undoManager.undo()
        sender.isEnabled = undoManager.canUndo
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem) {
        guard let undoManager = textView.undoManager else { return }
        undoManager.redo()
        sender.isEnabled = undoManager.canRedo
    }
        
    
    @IBAction func finishHighlight(_ sender: Any) {
        Feedback.success()
        setupForNormal()
        saveNoteIfNeeded(textView: textView)
    }
    
    
    
    @IBAction func trash(_ sender: Any) {
        
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExperiencedDeleteNote) {
            Alert.trash(from: self) { [weak self] in
                guard let `self` = self else { return }
                self.moveTrashAndPop()
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExperiencedDeleteNote)
            }
            return
        }
            
        
        moveTrashAndPop()
    }
    
    private func moveTrashAndPop() {
        note.managedObjectContext?.performAndWait {
            note.isInTrash = true
            note.managedObjectContext?.saveIfNeeded()
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func action(_ sender: Any) {
        
    }
    
    @IBAction func plus(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        textAccessoryVC?.collectionView.indexPathsForSelectedItems?.forEach {
            textAccessoryVC?.collectionView.deselectItem(at: $0, animated: false)
        }
        
        View.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self = self else { return }
            self.textAccessoryContainerView.isHidden = !sender.isSelected
        })
        
        if !sender.isSelected {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        if sender.isSelected {
            textView.contentInset.bottom += 50
        } else {
            textView.contentInset.bottom -= 50
        }
    }
    
    @IBAction func copyText(_ sender: Any) {
        Feedback.success()
        UIPasteboard.general.string = textView.text
        transparentNavigationController?.show(message: "⚡️복사 완료⚡️".loc)
    }
    
    
}

extension DetailViewController: CLLocationManagerDelegate {
    
}
