//
//  MailPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

/// Gmail 수신함 label.
let GTLRGmailInboxLabel = "INBOX"
/// Gmail 발신함 label.
let GTLRGmailSentLabel = "SENT"

class MailPickerTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private lazy var signInButton = GIDSignInButton()
    private let service = GTLRGmailService()
    private var user: GIDGoogleUser!
    
    private var fetchedData = [GTLRGmail_Message]()
    private var cachedData = [String : [Int : [String : String]]]()
    
    private var pageToken = ["token" : "", "temp" : ""]
    private var currentLabel = GTLRGmailInboxLabel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Google options.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        // Init cachedData.
        cachedData[GTLRGmailInboxLabel] = [Int : [String : String]]()
        cachedData[GTLRGmailSentLabel] = [Int : [String : String]]()
        tableView.setEditing(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.title = currentLabel.lowercased().loc
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentUser = GIDSignIn.sharedInstance().currentUser {
            tableView.isHidden = false
            signInButton.removeFromSuperview()
            user = currentUser
            requestList()
        } else {
            tableView.isHidden = true
            view.addSubview(signInButton)
            requestLogin()
        }
    }
    
    @IBAction private func change(list button: UIBarButtonItem) {
        currentLabel = (currentLabel == GTLRGmailInboxLabel) ? GTLRGmailSentLabel : GTLRGmailInboxLabel
        navigationItem.rightBarButtonItem?.title = currentLabel.lowercased().loc
        tableView.setContentOffset(.zero, animated: false)
        requestList()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mailDetailVC = segue.destination as? MailDetailViewController {
            mailDetailVC.html = sender as? String
        }
    }
    
}

extension MailPickerTableViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let currentUser = user {
            self.user = currentUser
            requestList()
        }
    }
    
    private func requestList(_ next: Bool = false) {
        DispatchQueue.global().async {
            let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: self.user.userID)
            query.labelIds = [self.currentLabel]
            self.fetchedData.removeAll()
            if next {query.pageToken = self.pageToken["token"]}
            self.service.authorizer = self.user.authentication.fetcherAuthorizer()
            self.service.executeQuery(query) { (ticket, response, error) in
                guard let response = response as? GTLRGmail_ListMessagesResponse else {return}
                guard let messages = response.messages else {return}
                self.pageToken["temp"] = response.nextPageToken ?? "end"
                if next {
                    messages.forEach {self.fetchedData.append($0)}
                } else {
                    self.fetchedData = messages
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func requestLogin() {
        let safeArea = view.safeAreaLayoutGuide.layoutFrame
        signInButton.center = CGPoint(x: safeArea.midX, y: safeArea.midY)
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        present(viewController, animated: true)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true)
    }
    
}

extension MailPickerTableViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailTableViewCell") as! MailTableViewCell
        cell.configure(nil)
        if let cachedData = cachedData[currentLabel]![indexPath.row] {
            cell.configure(cachedData)
            selection(cell: indexPath)
        } else {
            requestMessage(indexPath) {
                cell.configure($0)
                self.selection(cell: indexPath)
            }
        }
        cell.cellDidSelected = {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        cell.contentDidSelected = {
            guard let cachedData = self.cachedData[self.currentLabel]![indexPath.row] else {return}
            guard let html = cachedData["html"] else {return}
            self.open(with: html)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {if cachedData[currentLabel]![$0.row] == nil {requestMessage($0)}}
        guard let lastIndex = indexPaths.last?.row, lastIndex >= fetchedData.count - 1 else {return}
        guard pageToken["token"] != pageToken["temp"], pageToken["temp"] != "end" else {return}
        pageToken["token"] = pageToken["temp"]
        requestList(true)
    }
    
    private func requestMessage(_ indexPath: IndexPath, _ completion: (([String : String]) -> ())? = nil) {
        DispatchQueue.global().async {
            guard let user = GIDSignIn.sharedInstance().currentUser else {return}
            guard indexPath.row < self.fetchedData.count else {return}
            guard let messageID = self.fetchedData[indexPath.row].identifier else {return}
            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: user.userID, identifier: messageID)
            self.service.executeQuery(query) { (ticket, response, error) in
                guard let response = response as? GTLRGmail_Message else {return}
                var data = [String : String]()
                data["identifier"] = messageID
                data["from"] = self.from(with: response.payload)
                data["date"] = response.payload?.headers?.first(where: {$0.name == "Date"})?.value
                data["subject"] = response.payload?.headers?.first(where: {$0.name == "Subject"})?.value
                data["snippet"] = response.snippet
                data["html"] = self.html(with: response.payload)
                self.cachedData[self.currentLabel]![indexPath.row] = data
                DispatchQueue.main.async {
                    completion?(data)
                }
            }
        }
    }
    
    private func from(with payload: GTLRGmail_MessagePart?) -> String! {
        if let from = payload?.headers?.first(where: {$0.name == "From"})?.value, !from.isEmpty {
            let replacedFrom = from.replacingOccurrences(of: "\"", with: "")
            return replacedFrom.sub(...replacedFrom.index(of: " "))
        }
        return ""
    }
    
    private func html(with payload: GTLRGmail_MessagePart?) -> String! {
        guard let mimeType = payload?.mimeType else {return ""}
        if mimeType.contains("multipart") {
            guard let parts = payload?.parts else {return ""}
            for part in parts {
                guard let mimeType = part.mimeType, mimeType.contains("html") else {continue}
                guard let base64url = part.body?.data else {continue}
                guard let base64 = Data(base64Encoded: self.base64(from: base64url)) else {continue}
                return String(data: base64, encoding: .utf8)
            }
        } else {
            guard let base64url = payload?.body?.data else {return ""}
            guard let base64 = Data(base64Encoded: self.base64(from: base64url)) else {return ""}
            return String(data: base64, encoding: .utf8)
        }
        return ""
    }
    
    private func base64(from base64url: String) -> String {
        var base64 = base64url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {base64.append(String(repeating: "=", count: 4 - base64.count % 4))}
        return base64
    }
    
    private func selection(cell indexPath: IndexPath) {
        guard let mailCollection = note?.mailCollection else {return}
        guard let targetMail = cachedData[currentLabel]![indexPath.row] else {return}
        switch mailCollection.contains(where: {($0 as! Mail).identifier == targetMail["identifier"]}) {
        case true: tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        case false: tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    private func open(with html: String) {
        performSegue(withIdentifier: "MailDetailViewController", sender: html)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle(rawValue: 3) ?? .insert
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    private func manageLink(_ indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let mailCollection = note.mailCollection else {return}
        guard let selectedMail = cachedData[currentLabel]![indexPath.row] else {return}
        switch mailCollection.contains(where: {($0 as! Mail).identifier == selectedMail["identifier"]}) {
        case true:
            for localMail in mailCollection {
                guard let localMail = localMail as? Mail else {continue}
                guard  localMail.identifier == selectedMail["identifier"] else {continue}
                note.removeFromMailCollection(localMail)
                break
            }
        case false:
            let localMail = Mail(context: viewContext)
            localMail.identifier = selectedMail["identifier"]
            localMail.from = selectedMail["from"]
            localMail.date = (selectedMail["date"]?.dataDetector as? Date) ?? Date()
            localMail.subject = selectedMail["subject"]
            localMail.snippet = selectedMail["snippet"]
            localMail.html = selectedMail["html"]
            localMail.label = currentLabel
            note.addToMailCollection(localMail)
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
