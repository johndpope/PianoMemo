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
        referralLabel.text = "💌 The number of people you invited".loc + ": \(Referral.shared.inviteCount)"
        if let link = Referral.shared.cachedLink {
            shareLinkButton.setTitle(link, for: .normal)
        }

        Referral.shared.refreshBalance { success in
            guard success else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.referralLabel.text = "💌 The number of people you invited".loc + ": \(Referral.shared.inviteCount)"
            }
        }
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

        enum ActionType {
            case generate, copy
        }

        func notify(type: ActionType, link: String) {
            switch type {
            case .generate:
                shareLinkButton.setTitle("✨Created✨".loc, for: .normal)
                shareLinkButton.backgroundColor = UIColor(red:0.92, green:0.33, blue:0.33, alpha:1.00)
            case .copy:
                shareLinkButton.setTitle("✨Copy completed✨".loc, for: .normal)
                shareLinkButton.backgroundColor = UIColor(red:0.37, green:0.57, blue:0.97, alpha:1.00)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                [weak self] in
                guard let self = self else { return }
                self.shareLinkButton.backgroundColor = UIColor.black

                self.shareLinkButton.setTitle(link, for: .normal)
            }
        }

        Feedback.success()

        if let cached = Referral.shared.cachedLink {
            UIPasteboard.general.string = cached
            notify(type: .copy, link: cached)
            return
        }

        activityIndicator.startAnimating()
        Referral.shared.generateLink { [weak self] link in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            UIPasteboard.general.string = link
            notify(type: .generate, link: link)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func handleFacebook(indexPath: IndexPath) {
            if let url = URL(string: "fb://profile/602234013303895".loc), Application.shared.canOpenURL(url) {
                Application.shared.open(url, options: [:], completionHandler: nil)
            } else {
                guard let url = URL(string: "https://www.facebook.com/ourlovepiano".loc), Application.shared.canOpenURL(url) else {
                    tableView.deselectRow(at: indexPath, animated: true)
                    return }
                Application.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        switch indexPath.row {
        case 4:
            ()
        case 6:
            sendEmail(withTitle: "Report bug & Suggest idea".loc)
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
            self.transparentNavigationController?.show(message: "The piano email address has been copied to the clipboard.".loc, textColor: Color.white, color: Color.darkGray)
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

