//
//  CalendarPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI

class CalendarPickerTableViewController: UITableViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private let eventStore = EKEventStore()
    private var fetchedEvents = [EKEvent]()
    private var displayEvents = [[String : [EKEvent]]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        fetch()
    }
    
}

extension CalendarPickerTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        let cal = Calendar.current
        guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
        guard let eventCal = eventStore.defaultCalendarForNewEvents else {return}
        let predic = eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: [eventCal])
        fetchedEvents = eventStore.events(matching: predic)
        for event in fetchedEvents {
            let secTitle = DateFormatter.style([.full]).string(from: event.startDate)
            if let index = displayEvents.index(where: {$0.keys.first == secTitle}) {
                displayEvents[index][secTitle]?.append(event)
            } else {
                displayEvents.append([secTitle : [event]])
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
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
        selection(cell: indexPath)
        cell.cellDidSelected = {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        cell.contentDidSelected = {
            self.open(with: event)
        }
        return cell
    }
    
    private func selection(cell indexPath: IndexPath) {
        guard let eventCollection = note?.eventCollection else {return}
        guard let secTitle = displayEvents[indexPath.section].keys.first else {return}
        guard let selectedEvent = displayEvents[indexPath.section][secTitle]?[indexPath.row] else {return}
        let selectedEventID = selectedEvent.calendarItemExternalIdentifier
        switch eventCollection.contains(where: {($0 as! Event).identifier == selectedEventID}) {
        case true: tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        case false: tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    private func open(with event: EKEvent) {
        let eventVC = EKEventViewController()
        eventVC.event = event
        navigationController?.pushViewController(eventVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle(rawValue: 3) ?? .insert
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    private func manageLink(_ indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let eventCollection = note.eventCollection else {return}
        guard let secTitle = displayEvents[indexPath.section].keys.first else {return}
        guard let selectedEvent = displayEvents[indexPath.section][secTitle]?[indexPath.row] else {return}
        let selectedEventID = selectedEvent.calendarItemExternalIdentifier
        switch eventCollection.contains(where: {($0 as! Event).identifier == selectedEventID}) {
        case true:
            for localEvent in eventCollection {
                guard let localEvent = localEvent as? Event else {continue}
                guard  localEvent.identifier == selectedEventID else {continue}
                note.removeFromEventCollection(localEvent)
                break
            }
        case false:
            let localEvent = Event(context: viewContext)
            localEvent.identifier = selectedEventID
            note.addToEventCollection(localEvent)
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
