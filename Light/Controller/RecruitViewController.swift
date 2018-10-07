//
//  RecruitViewController.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class RecruitViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layoutManager.delegate = self
        let text = "recruitText".loc
        let attrText = text.createFormatAttrString(fromPasteboard: false)
        textView.attributedText = attrText
       
    }

}


extension RecruitViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return Preference.lineSpacing
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        lineFragmentUsedRect.pointee.size.height -= Preference.lineSpacing
        return true
    }
}
