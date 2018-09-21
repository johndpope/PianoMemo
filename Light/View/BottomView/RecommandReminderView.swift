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
            guard let reminder = data as? EKReminder,
                let date = reminder.alarmDate else { return }
            isHidden = false
            titleLabel.text = reminder.title
            
            dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            completeButton.setTitle(Preference.checklistOffValue, for: .normal)
            completeButton.setTitle(Preference.checklistOnValue, for: .selected)
            completeButton.isSelected = reminder.isCompleted
            
            registerButton.titleLabel?.text = "터치하여 미리알림에 등록해보세요"
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
            newReminder.calendar = reminder.calendar
            
            do {
                try eventStore.save(newReminder, commit: true)
                
                DispatchQueue.main.async {
                    sender.titleLabel?.text = "등록완료"
                }
                
                UIView.animate(withDuration: 0.3, delay: 1, options: [], animations: {
                    self.isHidden = true
                }, completion: nil)
                
                UIView.animate(withDuration: 0.3, delay: 1, options: [], animations: {
                    self.isHidden = true
                }, completion: { (bool) in
                    guard bool else { return }
                    let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
                    textView.textStorage.replaceCharacters(in: paraRange, with: "")
                })
                
            } catch {
                print("register에서 저장하다 에러: \(error.localizedDescription)")
            }
            
        }
    }
}

