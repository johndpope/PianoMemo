//
//  ReminderPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderPickerTableViewController: UITableViewController {
    
    var note: Note!
    
    private let eventStore = EKEventStore()
    private var fetchedReminders = [EKReminder]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetch()
    }
    
}

extension ReminderPickerTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let reminderCollection = note.reminderCollection else {return}
        let predic = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predic) {
            guard let reminders = $0 else {return}
            self.fetchedReminders = reminders.filter { reminder in
                !reminder.isCompleted && !reminderCollection.contains(where: {
                    ($0 as! Reminder).identifier == reminder.calendarItemIdentifier
                })
            }
        }
    }
    
}

extension ReminderPickerTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedReminders.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderTableViewCell") as! ReminderTableViewCell
        cell.configure(fetchedReminders[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        link(at: indexPath)
    }
    
    private func link(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        let reminder = fetchedReminders.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        let localReminder = Reminder(context: viewContext)
        localReminder.identifier = reminder.calendarItemIdentifier
        localReminder.createdDate = reminder.creationDate
        localReminder.modifiedDate = reminder.lastModifiedDate
        note.addToReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
