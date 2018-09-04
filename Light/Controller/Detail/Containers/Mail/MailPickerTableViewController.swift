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

class MailPickerTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var note: Note? {
        get {
            return (navigationController?.parent as? DetailViewController)?.note
        } set {
            (navigationController?.parent as? DetailViewController)?.note = newValue
        }
    }
    
    private lazy var signInButton = GIDSignInButton()
    private let service = GTLRGmailService()
    private var user: GIDGoogleUser!
    
    private var fetchedData = [GTLRGmail_Message]()
    private var cachedData = [Int : [String : String]]()
    private var pageToken = ["token" : "", "temp" : ""]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentUser = GIDSignIn.sharedInstance().currentUser {
            self.user = currentUser
            requestList()
        } else {
            requestLogin()
        }
    }
    
}

extension MailPickerTableViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let currentUser = user else {return}
        self.user = currentUser
        requestList()
    }
    
    private func requestList(_ next: Bool = false) {
        tableView.isHidden = false
        signInButton.removeFromSuperview()
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: user.userID)
        if next {query.pageToken = pageToken["token"]}
        service.authorizer = user.authentication.fetcherAuthorizer()
        service.executeQuery(query) { (ticket, response, error) in
            guard let response = response as? GTLRGmail_ListMessagesResponse else {return}
            guard let messages = response.messages else {return}
            self.pageToken["temp"] = response.nextPageToken ?? "end"
            if next {
                messages.forEach {self.fetchedData.append($0)}
            } else {
                self.fetchedData = messages
            }
            self.tableView.reloadData()
        }
    }
    
    private func requestLogin() {
        tableView.isHidden = true
        view.addSubview(signInButton)
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
        if let cachedData = cachedData[indexPath.row] {
            cell.configure(cachedData)
        } else {
            requestMessage(indexPath) {cell.configure($0)}
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {if cachedData[$0.row] == nil {requestMessage($0)}}
        guard let lastIndex = indexPaths.last?.row, lastIndex >= fetchedData.count - 1 else {return}
        guard pageToken["token"] != pageToken["temp"], pageToken["temp"] != "finished" else {return}
        pageToken["token"] = pageToken["temp"]
        requestList(true)
    }
    
    private func requestMessage(_ indexPath: IndexPath, _ completion: (([String : String]) -> ())? = nil) {
        guard let user = GIDSignIn.sharedInstance().currentUser else {return}
        guard let messageID = fetchedData[indexPath.row].identifier else {return}
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: user.userID, identifier: messageID)
        service.executeQuery(query) { (ticket, response, error) in
            guard let response = response as? GTLRGmail_Message else {return}
            var data = [String : String]()
            data["identifier"] = messageID
            data["from"] = response.payload?.headers?.first(where: {$0.name == "From"})?.value
            data["from"] = data["from"]!.replacingOccurrences(of: "\"", with: "")
            data["from"] = data["from"]!.sub(...data["from"]!.index(of: " "))
            data["date"] = response.payload?.headers?.first(where: {$0.name == "Date"})?.value
            data["subject"] = response.payload?.headers?.first(where: {$0.name == "Subject"})?.value
            data["snippet"] = response.snippet
            if response.payload?.mimeType == "multipart/alternative" {
                if let parts = response.payload?.parts {
                    for part in parts where part.mimeType == "text/html" {
                        if let base64url = part.body?.data {
                            if let base64Data = Data(base64Encoded: self.base64(from: base64url)) {
                                if let html = String(data: base64Data, encoding: .utf8) {
                                    data["html"] = html
                                }
                            }
                        }
                    }
                }
            } else {
                if let base64url = response.payload?.body?.data {
                    if let base64Data = Data(base64Encoded: self.base64(from: base64url)) {
                        if let html = String(data: base64Data, encoding: .utf8) {
                            data["html"] = html
                        }
                    }
                }
            }
            self.cachedData[indexPath.row] = data
            completion?(data)
        }
    }
    
    private func base64(from base64url: String) -> String {
        var base64 = base64url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {base64.append(String(repeating: "=", count: 4 - base64.count % 4))}
        return base64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let mailCollection = note?.mailCollection else {return}
        let messageID = fetchedData[indexPath.row].identifier
        switch mailCollection.contains(where: {($0 as! Mail).identifier == messageID}) {
        case true: unlink(at: indexPath)
        case false: link(at: indexPath)
        }
    }
    
    private func link(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let selectedMail = cachedData[indexPath.row] else {return}
        let localMail = Mail(context: viewContext)
        localMail.identifier = selectedMail["identifier"]
        localMail.from = selectedMail["from"]
        localMail.date = selectedMail["date"]
        localMail.subject = selectedMail["subject"]
        localMail.snippet = selectedMail["snippet"]
        localMail.html = selectedMail["html"]
        note.addToMailCollection(localMail)
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext,
            let mailCollection = note.mailCollection else {return}
        guard let selectedMail = cachedData[indexPath.row] else {return}
        for localMail in mailCollection {
            guard let localMail = localMail as? Mail else {return}
            if localMail.identifier == selectedMail["identifier"] {
                note.removeFromMailCollection(localMail)
                break
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}
