//
//  SearchHistoryDelegate.swift
//  Piano
//
//  Created by hoemoon on 20/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class SearchHistoryDelegate: NSObject {
    weak var searchViewController: SearchViewController!

    private var histories: [String] {
        return UserDefaults.getHistories().reversed()
    }

    func addHistory(_ keyword: String) {
        UserDefaults.addSearchHistory(history: keyword)
    }

    func clearHistory() {
        UserDefaults.clearHistories()
    }
}

extension SearchHistoryDelegate: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return histories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: SearchHistoryCell.id, for: indexPath) as? SearchHistoryCell {
            cell.history = histories[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }
}


extension SearchHistoryDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchViewController.textField.text = histories[indexPath.row]
        searchViewController.textField.sendActions(for: .editingChanged)
    }
}
