//
//  RecommendTableView.swift
//  Light
//
//  Created by hoemoon on 30/08/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class RecommendTableView: UITableView {
    let cellSpacing: CGFloat = 10
    private var reminders = [EKReminder]()

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        register(ReminderRecommendCell.self, forCellReuseIdentifier: ReminderRecommendCell.identifier)
        translatesAutoresizingMaskIntoConstraints = false
        dataSource = self
        delegate = self
        rowHeight = 30
        isScrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDataSource(_ dataSource: [EKReminder]) {
        self.reminders = dataSource
    }
}

extension RecommendTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ReminderRecommendCell.identifier, for: indexPath) as? ReminderRecommendCell {
            cell.configure(reminders[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
}

extension RecommendTableView: UITableViewDelegate {

}

