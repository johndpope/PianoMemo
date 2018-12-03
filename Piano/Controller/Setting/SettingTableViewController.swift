//
//  SettingTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 6..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class SettingTableViewController: UITableViewController {
    
    @IBOutlet weak var referralLabel: UILabel!
    @IBOutlet var shareLinkButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var storageService: StorageService!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        referralLabel.text = "💌 나의 초대로 \(String(Referral.shared.inviteCount))명 가입".loc
        Referral.shared.refreshBalance { success in
            guard success else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print(Referral.shared.inviteCount, "Referral.shared.inviteCount")
                self.referralLabel.text = "💌 나의 초대로 \(String(Referral.shared.inviteCount))명 가입".loc
            }
        }
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    enum SecondSectionType: Int {
        case rate = 0
        case supporters
        case facebook
        case recruit
        case improve
        case ideaOrBug
        case store
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TrashTableViewController {
            des.storageService = storageService
            return
        }
    }

    @IBAction func tapShareLink(_ sender: Any) {
        func notify() {
            shareLinkButton.setTitle("✨ 복사 완료 ✨", for: .normal)
            shareLinkButton.backgroundColor = UIColor(red:0.37, green:0.57, blue:0.97, alpha:1.00)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                [weak self] in
                guard let self = self else { return }
                self.shareLinkButton.backgroundColor = UIColor.black
                self.shareLinkButton.setTitle("초대 링크 복사", for: .normal)
            }
        }

        Feedback.success()
        if let cached = UserDefaults.standard.string(forKey: "shareLink") {
            UIPasteboard.general.string = cached
            notify()
            return
        }
        activityIndicator.startAnimating()
        Referral.shared.generateLink { [weak self] link in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            UIPasteboard.general.string = link
            UserDefaults.standard.set(link, forKey: "shareLink")
            notify()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func handleFacebook(indexPath: IndexPath) {
            if let url = URL(string: "fb://profile/602234013303895"), Application.shared.canOpenURL(url) {
                Application.shared.open(url, options: [:], completionHandler: nil)
            } else {
                guard let url = URL(string: "https://www.facebook.com/ourlovepiano"), Application.shared.canOpenURL(url) else {
                    tableView.deselectRow(at: indexPath, animated: true)
                    return }
                Application.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        switch indexPath.row {
        case 4:
            ()
        case 6:
            sendEmail(withTitle: "아이디어 혹은 버그가 있어요!")
        case 8:
            handleFacebook(indexPath: indexPath)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingTableViewController {
    @IBAction func cancel(){
        dismiss(animated: true, completion: nil)
    }

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

}


extension SettingTableViewController: MFMailComposeViewControllerDelegate {
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

