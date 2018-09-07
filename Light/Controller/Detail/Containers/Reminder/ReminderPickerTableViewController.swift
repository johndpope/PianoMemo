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
        tableView.setEditing(true, animated: false)
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
            reminders.sorted(by: {!$0.isCompleted && $1.isCompleted}).forEach {
                self.fetchedReminders.append($0)
            }
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
        cell.configure(reminder)
        selection(cell: indexPath)
        cell.cellDidSelected = {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        cell.contentDidSelected = {
            
        }
        return cell
    }
    
    private func selection(cell indexPath: IndexPath) {
        guard let reminderCollection = note?.reminderCollection else {return}
        let targetReminder = fetchedReminders[indexPath.row]
        let selectedReminderID = targetReminder.calendarItemExternalIdentifier
        switch reminderCollection.contains(where: {($0 as! Reminder).identifier == selectedReminderID}) {
        case true: tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        case false: tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle(rawValue: 3) ?? .insert
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    private func manageLink(_ indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let reminderCollection = note.reminderCollection else {return}
        let selectedReminder = fetchedReminders[indexPath.row]
        let selectedReminderID = selectedReminder.calendarItemExternalIdentifier
        switch reminderCollection.contains(where: {($0 as! Reminder).identifier == selectedReminderID}) {
        case true:
            for localReminder in reminderCollection {
                guard let localReminder = localReminder as? Reminder else {continue}
                guard  localReminder.identifier == selectedReminderID else {continue}
                note.removeFromReminderCollection(localReminder)
                break
            }
        case false:
            let localReminder = Reminder(context: viewContext)
            localReminder.identifier = selectedReminderID
            note.addToReminderCollection(localReminder)
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
