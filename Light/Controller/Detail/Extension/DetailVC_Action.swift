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

protocol ContainerDatasource {
    func reset()
    func startFetch()
    
}

extension DetailViewController {
    
    @IBAction func highlight(_ sender: Any) {
        Feedback.success()
        setupForPiano()
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let item = sender as? UIBarButtonItem else {return}
        if note.record()?.share == nil {
            cloudManager?.share.operate(target: self, pop: item, note: self.note, thumbnail: textView, title: "Piano")
        } else {
            cloudManager?.share.configure(target: self, pop: item, note: self.note)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        Feedback.success()
        view.endEditing(true)
    }
    
    @IBAction func undo(_ sender: Any) {
        textView.undoManager?.undo()
    }
    
    @IBAction func redo(_ sender: Any) {
        textView.undoManager?.redo()
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
}
