//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var note: Note!
    @IBOutlet weak var textView: LightTextView!
    @IBOutlet weak var toolbar: UIToolbar!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setHighlightBarButton()
        
        setTextView(note: note)
    }
    
    private func setTextView(note: Note) {
        if let text = note.content {
            DispatchQueue.main.async { [weak self] in
                let attrString = NSAttributedString(string: text, attributes: Preference.defaultAttr)
                self?.textView.attributedText = attrString
                self?.textView.convertBulletAllParagraphIfNeeded()
            }
            
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CalendarTableViewController" {
            guard let naviVC = segue.destination as? UINavigationController else {return}
            guard let calendarVC = naviVC.topViewController as? CalendarTableViewController else {return}
            calendarVC.note = note
        } else if segue.identifier == "ReminderTableViewController" {
            guard let naviVC = segue.destination as? UINavigationController else {return}
            guard let reminderVC = naviVC.topViewController as? ReminderTableViewController else {return}
            reminderVC.note = note
        } else if segue.identifier == "ContactTableViewController" {
            guard let naviVC = segue.destination as? UINavigationController else {return}
            guard let contactVC = naviVC.topViewController as? ContactTableViewController else {return}
            contactVC.note = note
        } else if segue.identifier == "PhotoCollectionViewController" {
            guard let naviVC = segue.destination as? UINavigationController else {return}
            guard let photoVC = naviVC.topViewController as? PhotoCollectionViewController else {return}
            photoVC.note = note
        }
    }

}

extension DetailViewController {
    private func setHighlightBarButton() {
        let barButton = BarButtonItem(title: "🖍", style: .plain, target: self, action: #selector(highlight(_:)))
        navigationItem.setRightBarButton(barButton, animated: true)

    }
    
    @IBAction func highlight(_ sender: Any) {
        setDoneBarButton()
        
    }
    
    private func setDoneBarButton() {
        let barButton = BarButtonItem(title: "🖌", style: .plain, target: self, action: #selector(highlight(_:)))
        navigationItem.setRightBarButton(barButton, animated: true)
        navigationItem.leftItemsSupplementBackButton = false
    }
    
    @IBAction func done(_ sender: Any) {
        setHighlightBarButton()
    }
}
