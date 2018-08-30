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
    
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }
    
    private let eventStore = EKEventStore()
    private var fetchedReminders = [EKReminder]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem(_:)))
        auth {self.fetch()}
    }
    
    @objc private func addItem(_ button: UIBarButtonItem) {
        //        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        //        let newAct = UIAlertAction(title: "create".loc, style: .default) { _ in
        //            self.newReminder()
        //        }
        //        let existAct = UIAlertAction(title: "import".loc, style: .default) { _ in
        self.performSegue(withIdentifier: "ReminderPickerTableViewController", sender: nil)
        //        }
        //        let cancelAct = UIAlertAction(title: "cencel".loc, style: .cancel)
        //        alert.addAction(newAct)
        //        alert.addAction(existAct)
        //        alert.addAction(cancelAct)
        //        present(alert, animated: true)
    }
    
    private func auth(_ completion: @escaping (() -> ())) {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            EKEventStore().requestAccess(to: .reminder) { status, error in
                DispatchQueue.main.async {
                    switch status {
                    case true : completion()
                    case false : self.alert()
                    }
                }
            }
        case .authorized: completion()
        case .restricted, .denied: alert()
        }
    }
    
    private func alert() {
        let alert = UIAlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let reminderPVC = segue.destination as? ReminderPickerTableViewController else {return}
        reminderPVC.note = note
    }
    
}

extension ReminderTableViewController {
    
    //    private func newReminder() {
    //
    //    }
    //
    //    private func insert(with event: EKReminder) {
    //        guard let viewContext = note.managedObjectContext else {return}
    //        let localReminder = Reminder(context: viewContext)
    //        localReminder.identifier = event.calendarItemIdentifier
    //        localReminder.createdDate = event.creationDate
    //        localReminder.modifiedDate = event.lastModifiedDate
    //        note.addToReminderCollection(localReminder)
    //        if viewContext.hasChanges {try? viewContext.save()}
    //    }
    //
    //    private func remove(with event: EKEvent) {
    //        guard let viewContext = note.managedObjectContext else {return}
    //        guard let localReminder = note.reminderCollection?.first(where: {($0 as! Reminder).identifier == event.calendarItemIdentifier}) as? Reminder else {return}
    //        note.removeFromReminderCollection(localReminder)
    //        if viewContext.hasChanges {try? viewContext.save()}
    //    }
    
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
                !reminder.isCompleted && reminderCollection.contains(where: {
                    ($0 as! Reminder).identifier == reminder.calendarItemIdentifier
                })
            }
            self.purge()
        }
    }
    
    private func purge() {
        guard let viewContext = note.managedObjectContext else {return}
        guard let reminderCollection = note.reminderCollection else {return}
        for reminder in reminderCollection {
            guard let reminder = reminder as? Reminder else {continue}
            if !fetchedReminders.contains(where: {$0.calendarItemIdentifier == reminder.identifier}) {
                note.removeFromReminderCollection(reminder)
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

