//
//  RewardTableViewController.swift
//  Piano
//
//  Created by hoemoon on 22/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import MessageUI

class RewardTableViewController: UITableViewController {
    @IBOutlet weak var referralCountLabel: UILabel!

//    @IBOutlet weak var durationLabel: UILabel!
//    @IBOutlet weak var durationLogPianoCountLable: UILabel!

    var durationCount: Int {
        return Logger.shared.loggedSeconds / 24 / 60 / 60
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.referralCountLabel.text = "\(String(Referral.shared.balance))명 초대"

//        self.durationLabel.text = "\(Logger.shared.formattedLog) 사용 중"
//        self.durationLogPianoCountLable.text = "\(durationCount) P"

        title = "\(Referral.shared.balance + durationCount) 피아노"

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
//            self.durationLabel.text = Logger.shared.formattedLog
//            self.durationLogPianoCountLable.text = "\(self.durationCount) P"

            self.title = "\(Referral.shared.balance + self.durationCount) 피아노"
        }
    }
}

extension RewardTableViewController {
    func sendEmail(withTitle: String) {
        let mailComposeViewController = configuredMailComposeViewController(withTitle: withTitle)
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.transparentNavigationController?.show(message: "피아노 이메일 주소가 클립보드로 복사되었습니다.", textColor: Color.white, color: Color.darkGray)
        }
    }

    func configuredMailComposeViewController(withTitle: String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property

        mailComposerVC.setToRecipients(["contact@pianotext.com"])
        mailComposerVC.setSubject(withTitle)

        let systemVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let body = "iOS\(systemVersion), device type: \(model)"
        mailComposerVC.setMessageBody(body, isHTML: false)

        return mailComposerVC
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch indexPath.row {
        case 3:
            Alert.warning(from: self, title: "조금만 기다려주세요", message: "곧 업데이트 됩니다!")
        case 4:
            sendEmail(withTitle: "아이디어 혹은 버그가 있어요!")
        default:
            break
        }
    }
}
extension RewardTableViewController: MFMailComposeViewControllerDelegate {
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

