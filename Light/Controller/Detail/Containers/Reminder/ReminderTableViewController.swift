//
//  ReminderTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderTableViewController: UITableViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private let eventStore = EKEventStore()
    private var fetchedReminders = [EKReminder]()
    
    var isNeedFetch = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isNeedFetch else {return}
        isNeedFetch = false
        startFetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ReminderPickerTableViewController" {
            guard let pickerVC = segue.destination as? ReminderPickerTableViewController else {return}
            pickerVC.reminderVC = self
        }
    }
    
}

extension ReminderTableViewController: ContainerDatasource {
    
    func reset() {
        fetchedReminders.removeAll()
    }
    
    func startFetch() {
        authAndFetch()
    }
    
}

extension ReminderTableViewController {
    
    private func authAndFetch() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            EKEventStore().requestAccess(to: .reminder) { (status, error) in
                DispatchQueue.main.async {
                    switch status {
                    case true : self.fetch()
                    case false : self.alert()
                    }
                }
            }
        case .authorized: fetch()
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
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        guard let reminderCollection = note?.reminderCollection else {return}
        var tempReminders = [EKReminder]()
        for localReminder in reminderCollection {
            guard let localReminder = localReminder as? Reminder, let id = localReminder.identifier else {continue}
            if let reminder = eventStore.calendarItems(withExternalIdentifier: id).first as? EKReminder {
                tempReminders.append(reminder)
            }
        }
        fetchedReminders = tempReminders
            .sorted(by: {$0.creationDate! < $1.creationDate!})
            .sorted(by: {!$0.isCompleted && $1.isCompleted})
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
        purge()
    }
    
    private func purge() {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let reminderCollection = note.reminderCollection else {return}
        var noteRemindersToDelete: [Reminder] = []
        for localReminder in reminderCollection {
            guard let localReminder = localReminder as? Reminder, let id = localReminder.identifier else {continue}
            if eventStore.calendarItems(withExternalIdentifier: id).isEmpty {
                noteRemindersToDelete.append(localReminder)
            }
        }
        noteRemindersToDelete.forEach {viewContext.delete($0)}
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
    
}
