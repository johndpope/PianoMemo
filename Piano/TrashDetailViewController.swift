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
    weak var syncController: Synchronizable!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup(note: note)
    }
    
    internal func setup(note: Note) {
        textView.isHidden = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let attrString = note.load()
            
            DispatchQueue.main.async {
                self.textView.isHidden = false
                self.textView.attributedText = attrString
            }
        }
    }
    
    @IBAction func deletePermanently(_ sender: Any) {
        syncController.purge(notes: [note]) {}
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func removeFromTrash(_ sender: Any) {
        syncController.restore(note: note) {}
        navigationController?.popViewController(animated: true)
    }
}
