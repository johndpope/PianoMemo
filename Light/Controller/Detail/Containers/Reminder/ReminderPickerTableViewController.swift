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
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
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
        eventStore.fetchReminders(matching: eventStore.predicateForReminders(in: nil)) {
            guard let reminders = $0 else {return}
            reminders.filter {!$0.isCompleted}.forEach {self.fetchedReminders.append($0)}
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
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
        let selectedReminderID = fetchedReminders[indexPath.row].calendarItemExternalIdentifier
        switch reminderCollection.contains(where: {($0 as! Reminder).identifier == selectedReminderID}) {
        case true: unlink(at: indexPath)
        case false: link(at: indexPath)
        }
    }
    
    private func link(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else { return }
        let selectedReminder = fetchedReminders[indexPath.row]
        let localReminder = Reminder(context: viewContext)
        localReminder.identifier = selectedReminder.calendarItemExternalIdentifier
        localReminder.creationDate = selectedReminder.creationDate
        localReminder.lastModifiedDate = selectedReminder.lastModifiedDate
        note.addToReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else { return }
        guard let reminderCollection = note.reminderCollection else { return }
        let selectedReminder = fetchedReminders[indexPath.row]
        for localReminder in reminderCollection {
            guard let localReminder = localReminder as? Reminder else {continue}
            if localReminder.identifier == selectedReminder.calendarItemExternalIdentifier {
                note.removeFromReminderCollection(localReminder)
                break
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}
