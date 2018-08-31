//
//  ReminderTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var suggestionTableView: ReminderSuggestionTableView!
    
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }
    
    private let eventStore = EKEventStore()
    private var fetchedReminders = [EKReminder]()
    
    private var suggestionTableTopConstraint: NSLayoutConstraint!
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanGesture(_:)))
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "reminder".loc
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem(_:)))
        auth {self.fetch()}
    }
    
    @objc private func addItem(_ button: UIBarButtonItem) {
        performSegue(withIdentifier: "ReminderPickerTableViewController", sender: nil)
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

extension ReminderViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            self.requestSuggestions()
        }
    }
    
    private func request() {
        guard let reminderCollection = note.reminderCollection else {return}
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
    
    private func requestSuggestions() {
        guard let reminderCollection = note.reminderCollection else {return}
        let predic = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predic) {
            guard let reminders = $0 else {return}
            let notesRemiderIDS = reminderCollection.map { $0 as? Reminder }
                .compactMap { $0 }
                .map { $0.identifier }
                .compactMap { $0 }
            let filtered = reminders.filter { !notesRemiderIDS.contains($0.calendarItemIdentifier) }
            self.refreshSuggestions(reminders: filtered)
        }
    }
    
}

extension ReminderViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedReminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderTableViewCell") as! ReminderTableViewCell
        cell.configure(fetchedReminders[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}

extension ReminderViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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

extension ReminderViewController {
    private func refreshSuggestions(reminders: [EKReminder]) {
        guard let content = note.content else { return }
        let filtered = content.tokenzied
            .map { token in reminders.filter { $0.title.lowercased().contains(token) } }
            .filter { $0.count != 0 }
            .flatMap { $0 }
        
        guard filtered.count > 0 else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.suggestionTableView.setupDataSource(Array(Set(filtered)))
            self?.setupRecommendTableView()
            self?.suggestionTableView.reloadData()
        }
    }
    
    private func setupRecommendTableView() {
        guard let controller = tabBarController, !view.subviews.contains(suggestionTableView) else { return }
        view.addSubview(suggestionTableView)
        let numberOfRows = CGFloat(suggestionTableView.numberOfRows(inSection: 0))
        let tabBarHeight:CGFloat = controller.tabBar.bounds.height
        let height = numberOfRows * suggestionTableView.rowHeight + suggestionTableView.headerHeight
        
        suggestionTableTopConstraint = suggestionTableView.topAnchor
            .constraint(equalTo: tableView.bottomAnchor, constant: -tabBarHeight - suggestionTableView.headerHeight)
        
        let constraints: [NSLayoutConstraint] = [
            suggestionTableView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            suggestionTableView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
            suggestionTableView.heightAnchor.constraint(equalToConstant: min(height, tableView.bounds.height * 0.7)),
            suggestionTableTopConstraint
        ]
        NSLayoutConstraint.activate(constraints)
        
        suggestionTableView.headerView.addGestureRecognizer(panGestureRecognizer)
        suggestionTableView.note = note
        suggestionTableView.refreshDelegate = self
        
    }
    
    @objc private func didPanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
        
        if panGestureRecognizer.velocity(in: suggestionTableView).y > 0 {
            // neutralize
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let `self` = self,
                    let suggestion = self.suggestionTableView,
                    let controller = self.tabBarController else { return }
                
                let tabBarHeight:CGFloat = controller.tabBar.bounds.height
                
                self.suggestionTableTopConstraint.constant = -tabBarHeight - suggestion.headerHeight
                self.view.layoutIfNeeded()
            }
        } else {
            // up
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let `self` = self,
                    let suggestion = self.suggestionTableView,
                    let controller = self.tabBarController else { return }
                
                let tabBarHeight:CGFloat = controller.tabBar.bounds.height
                let height = CGFloat(suggestion.numberOfRows(inSection: 0)) * suggestion.rowHeight
                    + suggestion.headerHeight
                    + tabBarHeight
                self.suggestionTableTopConstraint.constant = -min(height, self.tableView.bounds.height * 0.7)
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension ReminderViewController: ReminderSuggestionDelegate {
    func refreshReminderData() {
        fetch()
    }
}
