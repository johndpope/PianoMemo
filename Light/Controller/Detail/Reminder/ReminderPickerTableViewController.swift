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

    var note: Note? {
        get {
            return (navigationController?.parent as? DetailViewController)?.note
        } set {
            (navigationController?.parent as? DetailViewController)?.note = newValue
        }
    }
    
    
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
        }
    }
    
    private func request() {
        fetchedReminders.removeAll()
        eventStore.fetchReminders(matching: eventStore.predicateForReminders(in: nil)) {
            guard let reminders = $0 else {return}
            self.fetchedReminders = reminders.filter {!$0.isCompleted}
            DispatchQueue.main.async {
                self.tableView.reloadData()
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
        let reminder = fetchedReminders[indexPath.row]
        cell.configure(reminder, isLinked: note?.reminderCollection?.contains(reminder))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let reminderCollection = note?.reminderCollection else {return}
        let reminder = fetchedReminders[indexPath.row]
        switch reminderCollection.contains(where: {($0 as! Reminder).identifier == reminder.calendarItemIdentifier}) {
        case true: unlink(at: indexPath)
        case false: link(at: indexPath)
        }
    }
    
    private func link(at indexPath: IndexPath) {
        guard let note = note,
            let viewContext = note.managedObjectContext else { return }
        
        let reminder = fetchedReminders[indexPath.row]
        let localReminder = Reminder(context: viewContext)
        localReminder.identifier = reminder.calendarItemIdentifier
        localReminder.createdDate = reminder.creationDate
        localReminder.modifiedDate = reminder.lastModifiedDate
        note.addToReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext,
            let reminderCollection = note.reminderCollection else { return }
        
        let selectedReminder = fetchedReminders[indexPath.row]
        for reminder in reminderCollection {
            guard let reminder = reminder as? Reminder else {continue}
            if reminder.identifier == selectedReminder.calendarItemIdentifier {
                note.removeFromReminderCollection(reminder)
                break
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}

