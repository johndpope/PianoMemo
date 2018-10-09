//
//  TrashDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TrashDetailViewController: UIViewController {

    var note: Note!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup(note: note)
    }
    
    internal func setup(note: Note) {
        textView.isHidden = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let attrString = self.note.load()
            
            DispatchQueue.main.async {
                self.textView.isHidden = false
                self.textView.attributedText = attrString
            }
        }
    }
    
    @IBAction func deletePermanently(_ sender: Any) {
        //TODO COCOA:
        guard let context = note?.managedObjectContext else { return }
        context.performAndWait {
            context.delete(note)
            context.saveIfNeeded()
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func removeFromTrash(_ sender: Any) {
        //TODO COCOA:
        guard let context = note?.managedObjectContext else { return }
        context.performAndWait {
            note.isTrash = false
            note.modifiedAt = Date()
            context.saveIfNeeded()
            navigationController?.popViewController(animated: true)
        }
    }

    

}
