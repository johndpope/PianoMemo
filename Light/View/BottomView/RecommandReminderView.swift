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

    weak var mainViewController: MainViewController?
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
                    : "제목 없음".loc
                
                
                self.dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                self.completeButton.setTitle(Preference.checklistOffValue, for: .normal)
                self.completeButton.setTitle(Preference.checklistOnValue, for: .selected)
                self.completeButton.isSelected = reminder.isCompleted
                self.registerButton.setTitle("터치하여 미리알림에 등록해보세요.", for: .normal)
                
            }
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        
        guard let vc = mainViewController,
            let reminder = data as? EKReminder,
            let textView = vc.bottomView.textView else { return }
        
        Access.reminderRequest(from: vc) {
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
                    self.perform(#selector(self.finishRegistering(_:)), with: textView, afterDelay: 0.7)
                    sender.setTitle("미리알림에 등록 완료!", for: .normal)
                    
                }
                
            } catch {
                print("register에서 저장하다 에러: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func finishRegistering(_ textView: TextView) {
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        isHidden = true
    }
}

