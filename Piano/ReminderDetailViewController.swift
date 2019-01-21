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
    weak var detailVC: DetailViewController?
    @IBOutlet weak var topView: UIView!

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.minimumDate = Date()
        datePicker.minuteInterval = 5
        return datePicker
    }()

    @IBOutlet weak var dateButton: UIBarButtonItem!
    @IBOutlet weak var textView: GrowingTextView!
    @IBOutlet weak var alarmTextField: UITextField!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var eraseButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.placeholder = "Write down your work".loc
        textView.text = ekReminder.title
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

        textView.becomeFirstResponder()

        topView.layer.cornerRadius = 10
        topView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scheduleVC?.setupDataSource()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func pickerChanged(_ sender: UIDatePicker) {

        dateButton.title = DateFormatter.sharedInstance.string(from: sender.date)
    }

    private func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) != nil
            else { return }

        toolbarBottomConstraint.constant = kbHeight
//        UIView.animate(withDuration: duration) { [weak self] in
//            guard let self = self else { return }
//            self.toolbarBottomConstraint.constant = kbHeight
//            self.view.layoutIfNeeded()
//        }

    }

    @IBAction func tapDone(_ sender: Any) {
        if let count = textView.text?.count, count == 0 {
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
            return
        }

        ekReminder.title = textView.text
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
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
            DispatchQueue.main.async { [weak self] in
                let message = "✅ Reminder is successfully Registered✨".loc
                self?.detailVC?.transparentNavigationController?.show(message: message, color: Color.point)
            }

        } catch {
            print(error.localizedDescription)
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
            DispatchQueue.main.async { [weak self] in
                let message = "Please install the reminder application which is the basic application of iPhone🥰".loc
                self?.detailVC?.transparentNavigationController?.show(message: message, color: Color.point)
            }
        }

    }

    @IBAction func tapDate(_ sender: Any) {
        alarmTextField.becomeFirstResponder()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func tapEraseButton(_ sender: Any) {
        textView.text = ""
        textView.insertText("")
    }

}

extension ReminderDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        eraseButton.isEnabled = textView.text.count != 0
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        eraseButton.isEnabled = textView.text.count != 0
    }

}
