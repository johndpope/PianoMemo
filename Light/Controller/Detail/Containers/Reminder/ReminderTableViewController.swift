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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        auth {self.fetch()}
    }
    
}

extension ReminderTableViewController: ContainerDatasource {
    
    internal func reset() {
        fetchedReminders = []
        tableView.reloadData()
    }
    
    internal func startFetch() {
        
    }
    
}

extension ReminderTableViewController {
    
    private func auth(_ completion: @escaping (() -> ())) {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            EKEventStore().requestAccess(to: .reminder) { (status, error) in
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
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let reminderCollection = note?.reminderCollection?.sorted(by: {
            ($0 as! Reminder).linkedDate! < ($1 as! Reminder).linkedDate!}) else {return}
        fetchedReminders.removeAll()
        for localReminder in reminderCollection {
            guard let localReminder = localReminder as? Reminder, let id = localReminder.identifier else {continue}
            if let reminder = eventStore.calendarItems(withExternalIdentifier: id).first(where: {
                $0.creationDate == localReminder.creationDate}) as? EKReminder {
                fetchedReminders.append(reminder)
            }
        }
        purge()
    }
    
    private func purge() {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let reminderCollection = note.reminderCollection else {return}
        for localReminder in reminderCollection {
            guard let localReminder = localReminder as? Reminder else {continue}
            if !fetchedReminders.contains(where: {$0.calendarItemExternalIdentifier == localReminder.identifier}) {
                note.removeFromReminderCollection(localReminder)
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
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {return}
        unlink(at: indexPath)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let viewContext = note?.managedObjectContext else {return}
        let selectedReminderID = fetchedReminders.remove(at: indexPath.row).calendarItemExternalIdentifier
        tableView.deleteRows(at: [indexPath], with: .fade)
        guard let localReminder = note?.reminderCollection?.first(where: {
            ($0 as! Reminder).identifier == selectedReminderID}) as? Reminder else {return}
        note?.removeFromReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
