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
    
    var storageService: StorageService!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    enum SecondSectionType: Int {
        case rate = 0
        case supporters
        case facebook
        case recruit
        case improve
        case ideaOrBug
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TrashTableViewController {
            des.storageService = storageService
            return
        }
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath == IndexPath(row: 0, section: 1) {
            //사용가이드보기
            Alert.warning(from: self, title: "조금만 기다려주세요", message: "곧 업데이트 됩니다!")
        } else if indexPath == IndexPath(row: 1, section: 1) {
            sendEmail(withTitle: "아이디어 혹은 버그가 있어요!")
        } else if indexPath == IndexPath(row: 0, section: 2) {
            //피아노 별점주기
            Alert.warning(from: self, title: "미출시", message: "아직 출시 전이라 이 기능은 사용이 불가능해요.")
        } else if indexPath == IndexPath(row: 1, section: 2) {
            //피아노 서포터즈
            
        } else if indexPath == IndexPath(row: 2, section: 2) {
            if let url = URL(string: "fb://profile/602234013303895"), Application.shared.canOpenURL(url) {
                Application.shared.open(url, options: [:], completionHandler: nil)
            } else {
                guard let url = URL(string: "https://www.facebook.com/ourlovepiano"), Application.shared.canOpenURL(url) else {
                    tableView.deselectRow(at: indexPath, animated: true)
                    return }
                Application.shared.open(url, options: [:], completionHandler: nil)
                
            }
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
            Alert.warning(from: self, title: "Cannot send mail".loc, message: "Please check state of Internet or Device.".loc)
        }
    }
    
    func configuredMailComposeViewController(withTitle: String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["contact@pianotext.com"])
        mailComposerVC.setSubject(withTitle)
        
        return mailComposerVC
    }
}



extension SettingTableViewController: MFMailComposeViewControllerDelegate {
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
