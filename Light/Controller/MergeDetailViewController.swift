//
//  MergeDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 29/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class MergeDetailViewController: UIViewController {

    var note: Note!
    @IBOutlet weak var textView: DynamicTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.setup(note: note)
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
