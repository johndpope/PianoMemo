//
//  DetailVC_TextViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension DetailViewController: TextViewDelegate {
    
    func textViewDidChange(_ textView: TextView) {
        (textView as? DynamicTextView)?.hasEdit = true
        note.modifiedDate = Date()
    }
    
    func textViewDidEndEditing(_ textView: TextView) {
        textView.isEditable = false
    }
    
    func textViewDidBeginEditing(_ textView: TextView) {
        bottomButtons.forEach { $0.isSelected = false }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: ScrollView) {
        guard let textView = scrollView as? DynamicTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl,
            let pianoView = pianoView else { return }
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
        pianoControl.attach(on: textView)
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: ScrollView, willDecelerate decelerate: Bool) {
        guard let textView = scrollView as? DynamicTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl,
            let pianoView = pianoView else { return }
        
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
        pianoControl.attach(on: textView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: ScrollView) {
        guard let textView = scrollView as? DynamicTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl else { return }
        
        pianoControl.detach()
    }

}
