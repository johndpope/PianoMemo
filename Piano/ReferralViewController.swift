//
//  ReferralViewController.swift
//  Piano
//
//  Created by hoemoon on 15/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Branch

class ReferralViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(balanceChanged(_:)),
            name: .balanceChange,
            object: nil
        )



    }

    @IBAction func didTapButton() {
        Referral.shared.generateLink {
            print($0)
        }

        Branch.getInstance()?.userCompletedAction("load")
        

        Referral.shared.refreshBalance()
    }

    @IBAction func didTapRedeem() {
        Referral.shared.redeem(amount: 10)
    }

    @objc func balanceChanged(_ notification: Notification) {
        print(#function)
        print(notification.userInfo)
    }
}
