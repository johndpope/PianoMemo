//
//  MergeDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class MergeDetailViewController: UIViewController {
    var note: Note!
    weak var syncController: Synchronizable!
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 10, right: 10)
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
   
    private func setDelegate() {
        textView.layoutManager.delegate = self
    }
}

extension MergeDetailViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return Preference.lineSpacing
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        lineFragmentUsedRect.pointee.size.height -= Preference.lineSpacing
        return true
    }
}
