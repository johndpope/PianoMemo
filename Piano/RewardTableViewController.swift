//
//  RewardTableViewController.swift
//  Piano
//
//  Created by hoemoon on 22/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class RewardTableViewController: UITableViewController {
    @IBOutlet weak var referralCountLabel: UILabel!
    @IBOutlet weak var dutationLogLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dutationLogLabel.text = Logger.shared.formattedLog
        self.referralCountLabel.text = String(Referral.shared.balance)

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
            self.dutationLogLabel.text = Logger.shared.formattedLog
        }

        Referral.shared.refreshBalance {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.referralCountLabel.text = String(Referral.shared.balance)
            }
        }
    }
}
