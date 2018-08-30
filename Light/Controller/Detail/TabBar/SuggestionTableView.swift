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
    let cellSpacing: CGFloat = 10

    private var reminders = [EKReminder]()

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        register(ReminderSuggestionCell.self, forCellReuseIdentifier: ReminderSuggestionCell.identifier)
        translatesAutoresizingMaskIntoConstraints = false
        dataSource = self
        delegate = self
        rowHeight = 50
        backgroundColor = .clear
        separatorStyle = .none
        isScrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDataSource(_ dataSource: [EKReminder]) {
        self.reminders = dataSource
    }
}

extension SuggestionTableView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return reminders.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacing
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let clearView = UIView()
        clearView.backgroundColor = .clear
        return clearView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ReminderSuggestionCell.identifier, for: indexPath) as? ReminderSuggestionCell {
            cell.configure(reminders[indexPath.section])
            return cell
        }
        return UITableViewCell()
    }
}

extension SuggestionTableView: UITableViewDelegate {

}

