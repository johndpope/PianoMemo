//
//  ReminderDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 28/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderDetailViewController: UIViewController {
    var eventStore: EKEventStore!
    var ekReminder: EKReminder!
    weak var scheduleVC: ScheduleViewController?
    
    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.minimumDate = Date()
        datePicker.minuteInterval = 5
        return datePicker
    }()
    
    @IBOutlet weak var dateButton: UIBarButtonItem!
    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var alarmTextField: UITextField!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textfield.text = ekReminder.title
        if let date = ekReminder.alarmDate {
            datePicker.date = date
            dateButton.title = DateFormatter.sharedInstance.string(from: date)
        } else {
            let date = Date()
            datePicker.date = date
           dateButton.title = DateFormatter.sharedInstance.string(from: date)
        }
        alarmTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(pickerChanged(_:)), for: .valueChanged)
        
        textfield.becomeFirstResponder()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scheduleVC?.setupDataSource()
    }
    
    @IBAction func pickerChanged(_ sender: UIDatePicker) {
       
        dateButton.title = DateFormatter.sharedInstance.string(from: sender.date)
    }
    
    private func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    private func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        toolbarBottomConstraint.constant = kbHeight
    }
    
    @IBAction func tapDone(_ sender: Any) {
        if let count = textfield.text?.count, count == 0 {
            dismiss(animated: true, completion: nil)
            return
        }
        
        ekReminder.title = textfield.text
        if let alarms = ekReminder.alarms {
            alarms.forEach {
                ekReminder.removeAlarm($0)
            }
        }
        
        //현재 날짜보다 피커 날짜가 작다면(시간 차) 5초 뒤로 세팅
        let absoluteDate: Date = datePicker.date < Date() ? Date(timeIntervalSinceNow: 5) : datePicker.date
        let ekAlarm = EKAlarm(absoluteDate: absoluteDate)
        ekReminder.addAlarm(ekAlarm)
        
        do {
            try eventStore.save(ekReminder, commit: true)
        } catch {
            print(error.localizedDescription)
        }
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapDate(_ sender: Any) {
        alarmTextField.becomeFirstResponder()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
}

extension ReminderDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        alarmTextField.becomeFirstResponder()
        return true
    }
    
    
}
