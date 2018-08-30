//
//  CalendarTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI

class CalendarTableViewController: UITableViewController {
    
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }
    
    private let eventStore = EKEventStore()
    private var fetchedEvents = [EKEvent]()
    private var displayEvents = [[String : [EKEvent]]]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "event".loc
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem(_:)))
        auth {self.fetch()}
    }
    
    @objc private func addItem(_ button: UIBarButtonItem) {
        //        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        //        let newAct = UIAlertAction(title: "create".loc, style: .default) { _ in
        //            self.newEvent()
        //        }
        //        let existAct = UIAlertAction(title: "import".loc, style: .default) { _ in
        self.performSegue(withIdentifier: "CalendarPickerTableViewController", sender: nil)
        //        }
        //        let cancelAct = UIAlertAction(title: "cencel".loc, style: .cancel)
        //        alert.addAction(newAct)
        //        alert.addAction(existAct)
        //        alert.addAction(cancelAct)
        //        present(alert, animated: true)
    }
    
    private func auth(_ completion: @escaping (() -> ())) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            EKEventStore().requestAccess(to: .event) { status, error in
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
        let alert = UIAlertController(title: nil, message: "permission_event".loc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let calendarPVC = segue.destination as? CalendarPickerTableViewController else {return}
        calendarPVC.note = note
    }
    
}
extension CalendarTableViewController {
    //extension CalendarTableViewController: EKEventEditViewDelegate {
    //
    //    private func newEvent() {
    //        let eventVC = EKEventEditViewController()
    //        eventVC.eventStore = eventStore
    //        eventVC.event = EKEvent(eventStore: eventStore)
    //        eventVC.editViewDelegate = self
    //        present(eventVC, animated: true)
    //    }
    //
    //    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
    //        if let event = controller.event {
    //            if action == .saved {
    //                insert(with: event)
    //            } else if action == .deleted {
    //                remove(with: event)
    //            }
    //        }
    //        controller.dismiss(animated: true)
    //    }
    //
    //    private func insert(with event: EKEvent) {
    //        guard let viewContext = note.managedObjectContext else {return}
    //        let localEvent = Event(context: viewContext)
    //        localEvent.identifier = event.eventIdentifier
    //        note.addToEventCollection(localEvent)
    //        if viewContext.hasChanges {try? viewContext.save()}
    //    }
    //
    //    private func remove(with event: EKEvent) {
    //        guard let viewContext = note.managedObjectContext else {return}
    //        guard let localEvent = note.eventCollection?.first(where: {($0 as! Event).identifier == event.eventIdentifier}) as? Event else {return}
    //        note.removeFromEventCollection(localEvent)
    //        if viewContext.hasChanges {try? viewContext.save()}
    //    }
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            self.refine()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let eventCollection = note.eventCollection else {return}
        let cal = Calendar.current
        guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
        guard let eventCal = eventStore.defaultCalendarForNewEvents else {return}
        let predic = eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: [eventCal])
        fetchedEvents = eventStore.events(matching: predic).filter { event in
            eventCollection.contains(where: {($0 as! Event).identifier == event.eventIdentifier})
        }
        purge()
    }
    
    private func purge() {
        guard let viewContext = note.managedObjectContext else {return}
        guard let eventCollection = note.eventCollection else {return}
        for event in eventCollection {
            guard let event = event as? Event else {continue}
            if !fetchedEvents.contains(where: {$0.eventIdentifier == event.identifier}) {
                note.removeFromEventCollection(event)
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
    private func refine() {
        displayEvents.removeAll()
        for event in fetchedEvents {
            let secTitle = DateFormatter.style([.full]).string(from: event.startDate)
            if let index = displayEvents.index(where: {$0.keys.first == secTitle}) {
                displayEvents[index][secTitle]?.append(event)
            } else {
                displayEvents.append([secTitle : [event]])
            }
        }
    }
    
}

extension CalendarTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return displayEvents.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayEvents[section].values.first?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return displayEvents[section].keys.first ?? ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarTableViewCell") as! CalendarTableViewCell
        guard let event = displayEvents[indexPath.section].values.first?[indexPath.row] else {return UITableViewCell()}
        cell.configure(event)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let event = displayEvents[indexPath.section].values.first?[indexPath.row] else {return}
        open(with: event)
    }
    
    private func open(with event: EKEvent) {
        let eventVC = EKEventViewController()
        eventVC.event = event
        navigationController?.pushViewController(eventVC, animated: true)
    }
    
}

extension CalendarTableViewController {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {return}
        unlink(at: indexPath)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let secTitle = displayEvents[indexPath.section].keys.first else {return}
        guard let event = displayEvents[indexPath.section][secTitle]?.remove(at: indexPath.row) else {return}
        if displayEvents[indexPath.section][secTitle]!.isEmpty {displayEvents.remove(at: indexPath.section)}
        if tableView.numberOfRows(inSection: indexPath.section) <= 1 {
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        guard let viewContext = note.managedObjectContext else {return}
        guard let localEvent = note.eventCollection?.first(where: {($0 as! Event).identifier == event.eventIdentifier}) as? Event else {return}
        note.removeFromEventCollection(localEvent)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

