//
//  IndicatorTableView.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct Indicator {
    enum IndicatorType: String {
        case reminder
        case calendar
        case contact
    }
    let date = Date()
    let type: IndicatorType
    let title: String
    let subtitle: String = ""
    let desc: String = ""
}

extension Indicator: Hashable {
    var hashValue: Int {
        return date.hashValue
    }

    static func == (lhs: Indicator, rhs: Indicator) -> Bool {
        return lhs.date == rhs.date
    }
}

class IndicatorTableView: UITableView {
    static let rowHeight: CGFloat = 30

    private var indicators = [Indicator]()
    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = self
        delegate = self
        separatorStyle = .none
        backgroundColor = .none
    }

    func refresh(_ newIndicators: [Indicator]) {
        self.indicators = newIndicators
            .sorted { $0.date < $1.date }
        reloadData()
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
extension IndicatorTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IndicatorTableView.rowHeight
    }
}
