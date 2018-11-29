//
//  RewardTableViewController.swift
//  Piano
//
//  Created by hoemoon on 22/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import MessageUI

struct Reward {
    let title: String
    let point: Int
}

class RewardViewController: UIViewController {
    @IBOutlet weak var referralCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var rewards = [Reward]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.referralCountLabel.text = "💌 나의 초대로 \(String(Referral.shared.inviteCount))명 가입"
        title = "🎹 \(Referral.shared.creditCount) 건반"
        tableView.tableFooterView = UIView(frame: CGRect.zero)

        rewards.append(Reward(title: "aaa", point: 10))
        tableView.reloadData()
    }
}

extension RewardViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rewards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: RewardCell.id, for: indexPath) as? RewardCell {
            cell.reward = rewards[indexPath.row]
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
