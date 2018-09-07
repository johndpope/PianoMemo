//
//  CalendarTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI

class CalendarTableViewController: UITableViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private let eventStore = EKEventStore()
    private var fetchedEvents = [[String : [EKEvent]]]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        auth {self.fetch()}
    }
    
}

extension CalendarTableViewController: ContainerDatasource {
    
    func reset() {
        
    }
    
    func startFetch() {
        
    }
    
}

extension CalendarTableViewController {
    
    private func auth(_ completion: @escaping (() -> ())) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            EKEventStore().requestAccess(to: .event) { (status, error) in
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
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        guard let eventCollection = note?.eventCollection else {return}
        var tempEvents = [EKEvent]()
        for localEvent in eventCollection {
            guard let localEvent = localEvent as? Event, let id = localEvent.identifier else {continue}
            if let event = eventStore.calendarItems(withExternalIdentifier: id).first as? EKEvent {
                tempEvents.append(event)
            }
        }
        tempEvents = tempEvents.sorted(by: {$0.occurrenceDate < $1.occurrenceDate})
        fetchedEvents.removeAll()
        for event in tempEvents {
            let secTitle = DateFormatter.style([.full]).string(from: event.startDate)
            if let index = fetchedEvents.index(where: {$0.keys.first == secTitle}) {
                fetchedEvents[index][secTitle]?.append(event)
            } else {
                fetchedEvents.append([secTitle : [event]])
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
        purge()
    }
    
    private func purge() {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let eventCollection = note.eventCollection else {return}
        var noteEventsToDelete: [Event] = []
        for localEvent in eventCollection {
            guard let localEvent = localEvent as? Event, let id = localEvent.identifier else {continue}
            if eventStore.calendarItems(withExternalIdentifier: id).isEmpty {
                noteEventsToDelete.append(localEvent)
            }
        }
        noteEventsToDelete.forEach {viewContext.delete($0)}
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension CalendarTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedEvents.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedEvents[section].values.first?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedEvents[section].keys.first ?? ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarTableViewCell") as! CalendarTableViewCell
        guard let event = fetchedEvents[indexPath.section].values.first?[indexPath.row] else {return UITableViewCell()}
        cell.configure(event)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let selectedEvent = fetchedEvents[indexPath.section].values.first?[indexPath.row] else {return}
        open(with: selectedEvent)
    }
    
    private func open(with event: EKEvent) {
        let eventVC = EKEventViewController()
        eventVC.allowsEditing = false
        eventVC.event = event
        navigationController?.pushViewController(eventVC, animated: true)
    }
    
}
