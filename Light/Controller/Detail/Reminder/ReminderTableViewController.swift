//
//  ReminderTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderTableViewController: UITableViewController, ContainerDatasource {
    
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

    }
    
    internal func reset() {
        fetchedReminders = []
        tableView.reloadData()
    }
    
    internal func startFetch() {
        auth {self.fetch()}
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


    // MARK: - Table view data source
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {return}
        unlink(at: indexPath)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let viewContext = note?.managedObjectContext else {return}
        let reminder = fetchedReminders.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        guard let localReminder = note?.reminderCollection?.first(where: {($0 as! Reminder).identifier == reminder.calendarItemIdentifier}) as? Reminder else {return}
        note?.removeFromReminderCollection(localReminder)
        if viewContext.hasChanges {try? viewContext.save()}
    }
 

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ReminderTableViewController {
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
        fetchedReminders.removeAll()
        for localReminder in reminderCollection {
            guard let localReminder = localReminder as? Reminder, let id = localReminder.identifier else {continue}
            guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {continue}
            fetchedReminders.append(reminder)
        }
        purge()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func purge() {
        guard let note = note,
            let viewContext = note.managedObjectContext,
            let reminderCollection = note.reminderCollection else { return }
        
        for reminder in reminderCollection {
            guard let reminder = reminder as? Reminder else {continue}
            if !fetchedReminders.contains(where: {$0.calendarItemIdentifier == reminder.identifier}) {
                note.removeFromReminderCollection(reminder)
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
}
