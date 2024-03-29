//
//  CalendarViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI

class CalendarViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var suggestionTableView: CalendarSuggestionTableView!

    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }

    private let eventStore = EKEventStore()
    private var fetchedEvents = [EKEvent]()
    private var displayEvents = [[String: [EKEvent]]]()

    private var suggestionTableTopConstraint: NSLayoutConstraint!
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanGesture(_:)))
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        auth {self.fetch()}
    }

    private func auth(_ completion: @escaping (() -> Void)) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            EKEventStore().requestAccess(to: .event) { status, _ in
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
extension CalendarViewController {

    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            self.requestSuggestions()
        }
    }

    private func request() {
        guard let eventCollection = note.eventCollection else {return}
        fetchedEvents.removeAll()
        for localEvent in eventCollection {
            guard let localEvent = localEvent as? Event, let id = localEvent.identifier else {continue}
            guard let event = eventStore.event(withIdentifier: id) else {continue}
            fetchedEvents.append(event)
        }
        purge()
        refine()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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
                displayEvents.append([secTitle: [event]])
            }
        }
    }

    private func requestSuggestions() {
        guard let eventCollection = note.eventCollection else {return}
        let cal = Calendar.current
        guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
        guard let eventCal = eventStore.defaultCalendarForNewEvents else {return}
        let predic = eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: [eventCal])
        let noteEventIDs = eventCollection.map { $0 as? Event }
            .compactMap { $0 }
            .map { $0.identifier }
            .compactMap { $0 }
        let filtered = eventStore.events(matching: predic).filter { !noteEventIDs.contains($0.eventIdentifier) }
        refreshSuggestions(suggestions: filtered)
    }

}

extension CalendarViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return displayEvents.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayEvents[section].values.first?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return displayEvents[section].keys.first ?? ""
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarTableViewCell") as! CalendarTableViewCell
        guard let event = displayEvents[indexPath.section].values.first?[indexPath.row] else {return UITableViewCell()}
        cell.configure(event)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

extension CalendarViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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

extension CalendarViewController {
    private func refreshSuggestions(suggestions: [EKEvent]) {
        guard let content = note.content else { return }
        let filtered = content.tokenzied
            .map { token in suggestions.filter { $0.title.lowercased().contains(token) } }
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
        let tabBarHeight: CGFloat = controller.tabBar.bounds.height
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

                let tabBarHeight: CGFloat = controller.tabBar.bounds.height

                self.suggestionTableTopConstraint.constant = -tabBarHeight - suggestion.headerHeight
                self.view.layoutIfNeeded()
            }
        } else {
            // up
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let `self` = self,
                    let suggestion = self.suggestionTableView,
                    let controller = self.tabBarController else { return }

                let tabBarHeight: CGFloat = controller.tabBar.bounds.height
                let height = CGFloat(suggestion.numberOfRows(inSection: 0)) * suggestion.rowHeight
                    + suggestion.headerHeight
                    + tabBarHeight
                self.suggestionTableTopConstraint.constant = -min(height, self.tableView.bounds.height * 0.7)
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension CalendarViewController: CalendarSuggestionDelegate {
    func refreshCalendarData() {
        fetch()
    }
}
