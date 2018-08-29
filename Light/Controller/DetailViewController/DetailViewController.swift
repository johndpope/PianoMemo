//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class DetailViewController: UIViewController {

    
    @IBOutlet weak var textView: LightTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let note = (tabBarController as? DetailTabBarViewController)?.note else { return }
        setTextView(note: note)
        
        
        let barButton = BarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
        navigationItem.setRightBarButton(barButton, animated: true)
    }
    
    @IBAction func add(_ sender: Any) {
        
    }
    
    private func setTextView(note: Note) {
        if let text = note.content {
            DispatchQueue.main.async { [weak self] in
                let attrString = NSAttributedString(string: text, attributes: Preference.defaultAttr)
                self?.textView.attributedText = attrString
                self?.textView.convertBulletAllParagraphIfNeeded()
                
                if let date = note.modifiedDate {
                    let string = DateFormatter.sharedInstance.string(from:date)
                    self?.textView.setDescriptionLabel(text: string)
                }
            }
            
            
        }
    }
    
}

extension DetailViewController {
    
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
    
    @IBAction private func action(event: UIBarButtonItem) {
        auth(check: .event) {
            self.performSegue(withIdentifier: "CalendarTableViewController", sender: nil)
        }
    }
    
    @IBAction private func action(reminder: UIBarButtonItem) {
        auth(check: .reminder) {
            self.performSegue(withIdentifier: "ReminderTableViewController", sender: nil)
        }
    }
    
    private func auth(check type: EKEntityType, _ completion: @escaping (() -> ())) {
        let message = (type == .event) ? "permission_event".loc : "permission_reminer".loc
        switch EKEventStore.authorizationStatus(for: type) {
        case .notDetermined:
            EKEventStore().requestAccess(to: type) { status, error in
                DispatchQueue.main.async {
                    switch status {
                    case true : completion()
                    case false : self.eventAuth(alert: message)
                    }
                }
            }
        case .authorized: completion()
        case .restricted, .denied: eventAuth(alert: message)
        }
    }
    
    private func eventAuth(alert message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
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
