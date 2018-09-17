//
//  MainVC_Action.swift
//  Piano
//
//  Created by Kevin Kim on 17/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension MainViewController {
    internal func setDoneBtn(){
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        doneBtn.tag = 1
        navigationItem.setRightBarButton(doneBtn, animated: true)
    }
    
    internal func setEditBtn(){
        let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        editBtn.tag = 0
        navigationItem.setRightBarButton(editBtn, animated: true)
    }
    
    internal func setNormalBtn() {
        let normalBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(normal(_:)))
        navigationItem.setRightBarButton(normalBtn, animated: true)
    }
    
    internal func setTrashBtn() {
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trash(_:)))
        trashBtn.isEnabled = false
        navigationItem.setLeftBarButton(trashBtn, animated: true)
    }
    
    internal func setSettingBtn() {
        let settingBtn = BarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(setting(_:)))
        navigationItem.setLeftBarButton(settingBtn, animated: true)
    }
    
    @IBAction func setting(_ sender: Any) {
        performSegue(withIdentifier: SettingTableViewController.identifier, sender: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        bottomView.textView.resignFirstResponder()
    }
    
    @IBAction func edit(_ sender: Any) {
        collectionView.allowsMultipleSelection = true
        bottomView.isHidden = true
        title = ""
        setNormalBtn()
        setTrashBtn()
    }
    
    @IBAction func normal(_ sender: Any) {
        collectionView.allowsMultipleSelection = false
        bottomView.isHidden = false
        setEditBtn()
        setSettingBtn()
    }
    
    @IBAction func trash(_ sender: Any) {
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExperiencedDeleteNote) {
            Alert.trash(from: self) { [weak self] in
                guard let `self` = self else { return }
                
                self.moveSelectedNotesToTrash()
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExperiencedDeleteNote)
            }
            return
        }
        
        moveSelectedNotesToTrash()
    }
    
    private func moveSelectedNotesToTrash() {
        
        guard let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems?.sorted(by: { $0.item > $1.item }) else { return }
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        backgroundContext.perform { [weak self] in
            guard let `self` = self else { return }
            indexPathsForSelectedItems.forEach {
                self.resultsController.object(at: $0).isInTrash = true
                self.backgroundContext.saveIfNeeded()
            }
            
        }
        
        
    }
}
