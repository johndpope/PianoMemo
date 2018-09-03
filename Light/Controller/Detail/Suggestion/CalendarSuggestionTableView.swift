////
////  CalendarSuggestionTableView.swift
////  Light
////
////  Created by hoemoon on 31/08/2018.
////  Copyright © 2018 Piano. All rights reserved.
////
//
//import UIKit
//import EventKit
//
//protocol CalendarSuggestionDelegate: class {
//    func refreshCalendarData()
//}
//
//class CalendarSuggenstionTableView: UITableView {
//    @IBOutlet weak var headerView: SuggestionTableHeaderView!
//    weak var note: Note!
//    weak var refreshDelegate: CalendarSuggestionDelegate!
//    let headerHeight: CGFloat = 50
//    private var events = [EKEvent]()
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
//    func setupDataSource(_ dataSource: [EKEvent]) {
//        self.events = dataSource
//        headerView.configure(title: "Suggestion", count: dataSource.count)
//    }
//
//}
//
//extension CalendarSuggenstionTableView: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return events.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarTableViewCell", for: indexPath) as? CalendarTableViewCell {
//            cell.configure(events[indexPath.row])
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
//extension CalendarSuggenstionTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let viewContext = note.managedObjectContext else {return}
//        let event = events[indexPath.row]
//        let localEvent = Event(context: viewContext)
//        localEvent.identifier = event.eventIdentifier
//        note.addToEventCollection(localEvent)
//        if viewContext.hasChanges {try? viewContext.save()}
//        events.remove(at: indexPath.row)
//        tableView.deleteRows(at: [indexPath], with: .fade)
//        refreshDelegate.refreshCalendarData()
//    }
//}
