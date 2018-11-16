//
//  ReferralViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class ReferralViewController: UIViewController {
    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "0 명"
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(balanceChanged(_:)),
            name: .balanceChange,
            object: nil
        )
        Referral.shared.refreshBalance()
    }

    @objc func balanceChanged(_ notification: Notification) {
        if let dict = notification.userInfo as? [String: Any],
            let balance = dict["balance"] as? Int {
            label.text = "\(String(balance / 100)) 명"
        }
    }
    

    @IBAction func tapCopy(_ sender: Any) {
        Referral.shared.generateLink { link in
            UIPasteboard.general.string = link
        }
    }
}
