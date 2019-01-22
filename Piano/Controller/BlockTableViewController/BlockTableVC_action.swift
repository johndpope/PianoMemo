//
//  BlockTableVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewController {
    
    @IBAction func tapTrash(_ sender: Any) {
        Feedback.success()
        navigationController?.popViewController(animated: true)
        Analytics.deleteNoteAt = "editorToolBar"
        noteHandler.remove(notes: [note])
    }
    
    @IBAction func tapTimer(_ sender: Any) {
        
    }
    
    @IBAction func tapPiano(_ sender: Any) {
        
    }
    
    @IBAction func tapShare(_ sender: Any) {
        
    }
    
    @IBAction func tapCompose(_ sender: Any) {
        
    }
    
    @IBAction func tapDonePiano(_ sender: Any) {
        
    }
    
    @IBAction func tapSelectScreenArea(_ sender: Any) {
        
    }
    
    @IBAction func tapReminder(_ sender: Any) {
        
    }
    
    @IBAction func tapCopy(_ sender: Any) {
        
    }
    
    @IBAction func tapCut(_ sender: Any) {
        
    }
    
    @IBAction func tapDelete(_ sender: Any) {
        
    }
    
    @IBAction func tapPermanentDelete(_ sender: Any) {
        
    }
    
    @IBAction func tapRestore(_ sender: Any) {
        
    }
    
}
