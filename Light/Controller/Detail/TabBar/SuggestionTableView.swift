//
//  SuggestionTableView.swift
//  Light
//
//  Created by hoemoon on 30/08/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class SuggestionTableView: UITableView {
    @IBOutlet weak var headerView: SuggestionTableHeaderView!

    private var reminders = [EKReminder]()

    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = self
        delegate = self
        rowHeight = 50
        backgroundColor = .clear
        separatorStyle = .none
        isScrollEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        tableHeaderView = headerView
    }

    func setupTableView(_ dataSource: [EKReminder]) {
        self.reminders = dataSource
        headerView.configure(title: "Suggestion", count: reminders.count)
    }
}

extension SuggestionTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderTableViewCell", for: indexPath) as? ReminderTableViewCell {
            cell.configure(reminders[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
}

extension SuggestionTableView: UITableViewDelegate {

}

