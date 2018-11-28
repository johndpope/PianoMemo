//
//  ScheduleViewController.swift
//  Piano
//
//  Created by Kevin Kim on 28/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKitUI

protocol Schedulable {
    
}

extension EKEvent: Schedulable {
    
}

extension EKReminder: Schedulable {
    
}

class ScheduleViewController: UIViewController {
    var eventStore = EKEventStore()
    var dataSource: [[Schedulable]] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        NotificationCenter.default.addObserver(self, selector: #selector(eventStoreChanged(_:)), name: Notification.Name.EKEventStoreChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    
    @objc func eventStoreChanged(_ notification: Notification) {
        setupDataSource()
    }

    
    private func setupDataSource() {
        let reminderCalendars = self.eventStore.calendars(for: .reminder)
        let reminderPredicate = self.eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: reminderCalendars)
        self.eventStore.fetchReminders(matching: reminderPredicate) { [weak self] (reminders) in
            guard let self = self,
                var reminders = reminders else { return }
            
            reminders.sort(by: { (left, right) -> Bool in
                let leftDate = left.alarmDate ?? Date(timeIntervalSinceNow: 60 * 60 * 24 * 365)
                let rightDate = right.alarmDate ?? Date(timeIntervalSinceNow: 60 * 60 * 24 * 365)
                return leftDate < rightDate
            })
            
            if reminders.count == 0 {
                DispatchQueue.main.async {
                    //TODO: reminders 갯수가 0이면 엠티스테이트 보여주기
                    self.emptyStateView.isHidden = true
                }
                return
            }
            
            self.dataSource.append(reminders)
            
            let eventCalendars = self.eventStore.calendars(for: .event)
            let eventPredicate = self.eventStore.predicateForEvents(withStart: Date(), end: Date(timeIntervalSinceNow: 60 * 60 * 24 * 365 * 2), calendars: eventCalendars)
            var events = self.eventStore.events(matching: eventPredicate)
            events.sort(by: { (left, right) -> Bool in
                return left.startDate < right.startDate
            })
            
            self.dataSource.append(events)
            
            DispatchQueue.main.async {
                if let count1 = self.dataSource.first?.count, let count2 = self.dataSource.last?.count, count1 == 0, count2 == 0 {
                    self.emptyStateView.isHidden = false
                }
                self.emptyStateView.isHidden = true
                self.tableView.reloadData()
            }
        }
        
    }

    @IBAction func tapCreateEvent(_ sender: BarButtonItem) {
        Access.eventRequest(from: self) {
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let event = EKEvent(eventStore: self.eventStore)
                let cal = self.eventStore.calendars(for: .event).first { (calendar) -> Bool in
                    return calendar.type == EKCalendarType.calDAV
                }
                event.startDate = Date()
                event.endDate = Date(timeIntervalSinceNow: 60 * 60)
                event.calendar = cal ?? self.eventStore.defaultCalendarForNewEvents
                
                let eventEditVC = EKEventEditViewController()
                eventEditVC.eventStore = self.eventStore
                eventEditVC.event = event
                eventEditVC.editViewDelegate = self
                self.present(eventEditVC, animated: true, completion: nil)
            }
            
        }
        
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

extension ScheduleViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch action {
        case .canceled:
            controller.dismiss(animated: true, completion: nil)
        case .saved, .deleted:
            controller.dismiss(animated: true, completion: nil)
            setupDataSource()
            
        }
        
    }
}

extension ScheduleViewController: EKEventViewDelegate {
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        controller.dismiss(animated: true, completion: nil)
        setupDataSource()
    }
    
    
}

extension ScheduleViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let reminder = dataSource[indexPath.section][indexPath.row] as? EKReminder {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell") as! ReminderCell
            cell.ekReminder = reminder
            cell.scheduleVC = self
            return cell
        } else if let event = dataSource[indexPath.section][indexPath.row] as? EKEvent {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell") as! EventCell
            cell.ekEvent = event
            cell.scheduleVC = self
            return cell
        } else {
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if let reminder = dataSource[indexPath.section][indexPath.row] as? EKReminder {
            let trashAction = UIContextualAction(style: .normal, title:  "🗑", handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                guard let self = self else { return }
                success(true)
                let message = "리마인더가 삭제 되었습니다.".loc
                
                do {
                    try self.eventStore.remove(reminder, commit: true)
                } catch {
                    print(error.localizedDescription)
                }
                
                self.dataSource[indexPath.section].remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.transparentNavigationController?.show(message: message, color: Color.redNoti)
                
            })
            trashAction.backgroundColor = Color.trash
            return UISwipeActionsConfiguration(actions: [trashAction])
        } else if let event = dataSource[indexPath.section][indexPath.row] as? EKEvent {
            let trashAction = UIContextualAction(style: .normal, title:  "🗑", handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                guard let self = self else { return }
                success(true)
                let message = "일정이 삭제 되었습니다.".loc
                
                do {
                    try self.eventStore.remove(event, span: EKSpan.thisEvent)
                } catch {
                    print(error.localizedDescription)
                }
                
                self.dataSource[indexPath.section].remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.transparentNavigationController?.show(message: message, color: Color.redNoti)
                
            })
            trashAction.backgroundColor = Color.trash
            return UISwipeActionsConfiguration(actions: [trashAction])
        } else {
            return nil
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section != 0 ? "일정".loc : "할 일".loc
    }
}

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let reminder = dataSource[indexPath.section][indexPath.row] as? EKReminder {
            performSegue(withIdentifier: ReminderDetailViewController.identifier, sender: reminder)
        } else if let event = dataSource[indexPath.section][indexPath.row] as? EKEvent {
            let eventEditVC = EKEventEditViewController()
            eventEditVC.eventStore = eventStore
            eventEditVC.event = event
            eventEditVC.editViewDelegate = self
            present(eventEditVC, animated: true, completion: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
