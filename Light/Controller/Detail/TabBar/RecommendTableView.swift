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
    private(set) var reminders = [EKReminder]()
    weak var eventStore: EKEventStore!

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        translatesAutoresizingMaskIntoConstraints = false
        dataSource = self
        delegate = self
        rowHeight = 30
        isScrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // note의 content를 이용해 추천으로 reminders를 업데이트 하기
    func refreshRecommendations(note: Note, reminders: [EKReminder]) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let `self` = self, let content = note.content else { return }
            let filtered = content.tokenzied
                .map { token in reminders.filter { $0.title.contains(token) } }
                .filter { $0.count != 0 }
                .flatMap { $0 }
            self.reminders = Array(Set(filtered))

            print(reminders)

            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
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

