//
//  CalendarTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI

class CalendarTableViewController: UITableViewController, ContainerDatasource {

    var note: Note? {
        get {
            return (navigationController?.parent as? DetailViewController)?.note
        } set {
            (navigationController?.parent as? DetailViewController)?.note = newValue
        }
    }

    private let eventStore = EKEventStore()
    private var fetchedEvents = [EKEvent]()
    private var displayEvents = [[String : [EKEvent]]]()
    
    internal func reset() {
        fetchedEvents = []
        displayEvents = []
        tableView.reloadData()
    }

    internal func startFetch() {
        auth {self.fetch()}
    }
    
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
        
        guard let note = note,
            let viewContext = note.managedObjectContext,
            let localEvent = note.eventCollection?
                .first(where: {($0 as! Event).identifier == event.eventIdentifier}) as? Event else { return }

        note.removeFromEventCollection(localEvent)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension CalendarTableViewController {
    
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
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let eventCollection = note?.eventCollection else {return}
        fetchedEvents.removeAll()
        for localEvent in eventCollection {
            guard let localEvent = localEvent as? Event, let id = localEvent.identifier else {continue}
            guard let event = eventStore.event(withIdentifier: id) else {continue}
            fetchedEvents.append(event)
        }
        purge()
        refine()
    }
    
    private func purge() {
        guard let viewContext = note?.managedObjectContext else {return}
        guard let eventCollection = note?.eventCollection else {return}
        for event in eventCollection {
            guard let event = event as? Event else {continue}
            if !fetchedEvents.contains(where: {$0.eventIdentifier == event.identifier}) {
                note?.removeFromEventCollection(event)
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
