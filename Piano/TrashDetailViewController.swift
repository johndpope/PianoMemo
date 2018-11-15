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
    weak var storageService: StorageService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layoutManager.delegate = self
        setup(note: note)
    }
    
    internal func setup(note: Note) {
        textView.isHidden = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
//            let attrString = note.load()
            
            DispatchQueue.main.async {
                self.textView.isHidden = false
//                self.textView.attributedText = attrString
            }
        }
    }
    
    @IBAction func deletePermanently(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        storageService.local.purge(notes: [note]) { }
        
    }
    
    @IBAction func removeFromTrash(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        storageService.local.restore(note: note) {}
    }
}

extension TrashDetailViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return Preference.lineSpacing
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        lineFragmentUsedRect.pointee.size.height -= Preference.lineSpacing
        return true
    }
}
