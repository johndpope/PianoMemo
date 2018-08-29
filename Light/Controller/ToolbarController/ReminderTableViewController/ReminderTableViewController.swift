//
//  ReminderTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderTableViewController: UITableViewController {
    
    var note: Note!
    
    private let eventStore = EKEventStore()
    private var fetchedReminders = [EKReminder]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetch()
    }
    
    @IBAction private func close(_ button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction private func addItem(_ button: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let newAct = UIAlertAction(title: "create".loc, style: .default) { _ in
            self.newReminder()
        }
        let existAct = UIAlertAction(title: "import".loc, style: .default) { _ in
            self.performSegue(withIdentifier: "ReminderPickerTableViewController", sender: nil)
        }
        let cancelAct = UIAlertAction(title: "cencel".loc, style: .cancel)
        alert.addAction(newAct)
        alert.addAction(existAct)
        alert.addAction(cancelAct)
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let reminderPVC = segue.destination as? ReminderPickerTableViewController else {return}
        reminderPVC.note = note
    }
    
}

extension ReminderTableViewController {
    
    private func newReminder() {
        
    }
    
    private func insert(with event: EKReminder) {
        guard let viewContext = note.managedObjectContext else {return}
        let localReminder = Reminder(context: viewContext)
        localReminder.identifier = event.calendarItemIdentifier
        localReminder.createdDate = event.creationDate
        localReminder.modifiedDate = event.lastModifiedDate
        note.addToReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
    private func remove(with event: EKEvent) {
        guard let viewContext = note.managedObjectContext else {return}
        guard let localReminder = note.reminderCollection?.first(where: {($0 as! Reminder).identifier == event.calendarItemIdentifier}) as? Reminder else {return}
        note.removeFromReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            self.purge()
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
                !reminder.isCompleted && reminderCollection.contains(where: {
                    ($0 as! Reminder).identifier == reminder.calendarItemIdentifier
                })
            }
        }
    }
    
    private func purge() {
        guard let viewContext = note.managedObjectContext else {return}
        guard let reminderCollection = note.reminderCollection else {return}
        for reminder in reminderCollection {
            if let reminder = reminder as? Reminder {
                if !fetchedReminders.contains(where: {$0.calendarItemIdentifier == reminder.identifier}) {
                    note.removeFromReminderCollection(reminder)
                }
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension ReminderTableViewController {
    
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
        open(with: fetchedReminders[indexPath.row])
    }
    
    private func open(with reminder: EKReminder) {
        
    }
    
}

extension ReminderTableViewController {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {return}
        unlink(at: indexPath)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        let reminder = fetchedReminders.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        guard let localReminder = note.reminderCollection?.first(where: {($0 as! Reminder).identifier == reminder.calendarItemIdentifier}) as? Reminder else {return}
        note.removeFromReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
