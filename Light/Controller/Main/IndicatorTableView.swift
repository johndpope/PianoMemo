//
//  IndicatorTableView.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class IndicatorTableView: UITableView {
    private var indicators = [Indicator]()
    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = self
        separatorStyle = .none
        backgroundColor = .none
        rowHeight = UITableViewAutomaticDimension
        estimatedRowHeight = 50
        indicatorStyle = .white
    }

    func refresh(_ newIndicators: [Indicator]) {
        self.indicators = newIndicators
            .sorted { $0.date < $1.date }
        reloadData()
        if indicators.count > 1 {
            scrollToRow(at: IndexPath(row: indicators.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
}

extension IndicatorTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indicators.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "IndicatorCell", for: indexPath) as? IndicatorCell {
            cell.configure(indicators[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
}
