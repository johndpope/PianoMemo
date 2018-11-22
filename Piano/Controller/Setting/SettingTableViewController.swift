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
    var storageService: StorageService!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        referralLabel.text = "나의 초대로 \(String(Referral.shared.balance))명 설치"
        Referral.shared.refreshBalance {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.referralLabel.text = "나의 초대로 \(String(Referral.shared.balance))명 설치"
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func balanceChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            if let dict = notification.userInfo as? [String: Any],
                let balance = dict["balance"] as? Int {
                self?.referralLabel.text = "나의 초대로 \(String(balance / 100))명 설치"
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TrashTableViewController {
            des.storageService = storageService
            return
        }
    }

    @IBAction func tapShareLink(_ sender: Any) {
        Referral.shared.generateLink { [weak self] link in
            UIPasteboard.general.string = link
            (self?.navigationController as? TransParentNavigationController)?.show(message: "복사 완료!".loc, color: Color.point)
            
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

        switch indexPath {
        case IndexPath(row: 2, section: 1):
            // 가이드 보기
            Alert.warning(from: self, title: "조금만 기다려주세요", message: "곧 업데이트 됩니다!")
        case IndexPath(row: 4, section: 1):
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
}
