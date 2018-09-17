//
//  DetailViewController.swift
//  Piano
//
//  Created by hoemoon on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class DetailViewController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    weak var note: Note! {
        willSet {
            guard let note = newValue,
                let content = note.content else { return }
            textView.string = content
        }
    }
}
extension DetailViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        // TODO: 저장 로직 개선하기
        guard let textView = notification.object as? NSTextView else { return }
        note.content = textView.string
        try? note.managedObjectContext?.save()
    }
}
