//
//  DetailViewController.swift
//  Piano
//
//  Created by hoemoon on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

protocol DetailPostActionDelegate: class {
    func didCloseDetailViewController(that note: Note)
}

class DetailViewController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    weak var postActionDelegate: DetailPostActionDelegate!
    weak var note: Note! {
        willSet {
            guard let note = newValue,
                let content = note.content else { return }
            textView.string = content
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        postActionDelegate.didCloseDetailViewController(that: note)
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
