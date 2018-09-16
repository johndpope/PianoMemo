////
////  ReminderSuggestionTableView.swift
////  Light
////
////  Created by hoemoon on 30/08/2018.
////  Copyright © 2018 Piano. All rights reserved.
////
//
//import UIKit
//import EventKit
//
//protocol ReminderSuggestionDelegate: class {
//    func refreshReminderData()
//}
//
//class ReminderSuggestionTableView: UITableView {
//    @IBOutlet weak var headerView: SuggestionTableHeaderView!
//    weak var note: Note!
//    weak var refreshDelegate: ReminderSuggestionDelegate!
//    let headerHeight: CGFloat = 50
//    private var reminders = [EKReminder]()
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        dataSource = self
//        delegate = self
//        rowHeight = 50
//        backgroundColor = .white
//        separatorStyle = .none
//        translatesAutoresizingMaskIntoConstraints = false
//    }
//
//    func setupDataSource(_ dataSource: [EKReminder]) {
//        self.reminders = dataSource
//        headerView.configure(title: "Suggestion", count: dataSource.count)
//    }
//}
//
//extension ReminderSuggestionTableView: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return reminders.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderTableViewCell", for: indexPath) as? ReminderTableViewCell {
//            cell.configure(reminders[indexPath.row])
//            return cell
//        }
//        return UITableViewCell()
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return headerView
//    }
//
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return headerHeight
//    }
//}
//
//extension ReminderSuggestionTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let viewContext = note.managedObjectContext else {return}
//        let reminder = reminders[indexPath.row]
//        let localReminder = Reminder(context: viewContext)
//        localReminder.identifier = reminder.calendarItemIdentifier
//        localReminder.createdDate = reminder.creationDate
//        localReminder.modifiedDate = reminder.lastModifiedDate
//        note.addToReminderCollection(localReminder)
//        if viewContext.hasChanges {try? viewContext.save()}
//        reminders.remove(at: indexPath.row)
//        tableView.deleteRows(at: [indexPath], with: .fade)
//        refreshDelegate.refreshReminderData()
//    }
//}
//
