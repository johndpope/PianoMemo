//
//  CalendarPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class CalendarPickerTableViewController: UITableViewController {
    
    var note: Note!
    
    private let eventStore = EKEventStore()
    private var fetchedEvents = [EKEvent]()
    private var displayEvents = [[String : [EKEvent]]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetch()
    }
    
}

extension CalendarPickerTableViewController {
    
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
            !eventCollection.contains(where: {($0 as! Event).identifier == event.eventIdentifier})
        }
    }
    
    private func refine() {
        displayEvents.removeAll()
        for event in fetchedEvents {
            let secTitle = DateFormatter.full.string(from: event.startDate)
            if let index = displayEvents.index(where: {$0.keys.first == secTitle}) {
                displayEvents[index][secTitle]?.append(event)
            } else {
                displayEvents.append([secTitle : [event]])
            }
        }
    }
    
}

extension CalendarPickerTableViewController {
    
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
        link(at: indexPath)
    }
    
    private func link(at indexPath: IndexPath) {
        guard let secTitle = displayEvents[indexPath.section].keys.first else {return}
        guard let event = displayEvents[indexPath.section][secTitle]?.remove(at: indexPath.row) else {return}
        if displayEvents[indexPath.section][secTitle]!.isEmpty {displayEvents.remove(at: indexPath.section)}
        if tableView.numberOfRows(inSection: indexPath.section) <= 1 {
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        guard let viewContext = note.managedObjectContext else {return}
        let localEvent = Event(context: viewContext)
        localEvent.identifier = event.eventIdentifier
        note.addToEventCollection(localEvent)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
