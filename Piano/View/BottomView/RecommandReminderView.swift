//
//  RecommandReminderView.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

protocol RecommandDataAcceptable {
    var data: Recommandable? { get set }
}

/**
 데이터만 넣어주면 자동 세팅
 */
class RecommandReminderView: UIView, RecommandDataAcceptable {

    private weak var viewController: ViewController?
    private weak var textView: TextView?
    
    func setup(viewController: ViewController, textView: TextView) {
        self.viewController = viewController
        self.textView = textView
    }
    
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    
    var data: Recommandable? {
        didSet {
            
            DispatchQueue.main.async { [ weak self] in
                guard let `self` = self else { return }
                
                guard let reminder = self.data as? EKReminder,
                    let date = reminder.alarmDate else {
                        self.isHidden = true
                        return
                }
                self.isHidden = false
                
                self.titleLabel.text = reminder.title.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
                    ? reminder.title
                    : "Untitled".loc
                
                
                self.dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                self.completeButton.setTitle("✅", for: .normal)
            }
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        
        guard let viewController = viewController,
            let reminder = data as? EKReminder,
            let textView = textView else { return }
        
        Access.reminderRequest(from: viewController) {
            let eventStore = EKEventStore()
            let newReminder = EKReminder(eventStore: eventStore)
            newReminder.title = reminder.title
            newReminder.alarms = reminder.alarms
            newReminder.isCompleted = reminder.isCompleted
            newReminder.calendar = eventStore.defaultCalendarForNewReminders()
            
            
            do {
                try eventStore.save(newReminder, commit: true)
                
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }                    
                    self.finishRegistering(textView)
                    let message = "✅ Reminder is successfully Registered✨".loc
                    viewController.transparentNavigationController?.show(message: message, color: Color.point)
                }
                
            } catch {
                print("register에서 저장하다 에러: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func finishRegistering(_ textView: TextView) {
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.delegate?.textViewDidChange?(textView)
        textView.typingAttributes = Preference.defaultAttr
        isHidden = true
    }
}

