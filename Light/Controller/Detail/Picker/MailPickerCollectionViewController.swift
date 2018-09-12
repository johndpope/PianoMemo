//
//  MailPickerCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 11..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

/// Gmail 수신함 label.
private let GTLRGmailInboxLabel = "INBOX"
/// Gmail 발신함 label.
private let GTLRGmailSentLabel = "SENT"

class MailPickerCollectionViewController: UICollectionViewController, NoteEditable {

    var note: Note!
    var mainContext: NSManagedObjectContext!
    var identifiersToDelete: [String] = []
    private lazy var signInButton = GIDSignInButton()
    private let service = GTLRGmailService()
    private var user: GIDGoogleUser!
    private var pageToken = ["token" : "", "temp" : ""]
    private var cachedData: [IndexPath : GTLRGmail_Message] = [:]
    
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView?.reloadData()
                self?.selectCollectionViewForConnectedMail()
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Google options.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        
        if let currentUser = GIDSignIn.sharedInstance().currentUser {
            user = currentUser
            appendMailsToDataSource()
        } else {
            requestLogin()
        }
        
        
        
        collectionView?.allowsMultipleSelection = true
        


    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mailDetailVC = segue.destination as? MailDetailViewController,
            let html = sender as? String {
            mailDetailVC.html = html
        }
    }

}

extension MailPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
    }
    

}

extension MailPickerCollectionViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let currentUser = user {
            self.user = currentUser
            appendMailsToDataSource()
        }
    }
    
    private func appendMailsToDataSource(_ next: Bool = false) {
        signInButton.removeFromSuperview()
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: self.user.userID)
            query.labelIds = ["INBOX"]
            self.dataSource.removeAll()
            
            
            
            if next {query.pageToken = self.pageToken["token"]}
            self.service.authorizer = self.user.authentication.fetcherAuthorizer()
            self.service.executeQuery(query) { (ticket, response, error) in
                guard let response = response as? GTLRGmail_ListMessagesResponse else {return}
                guard let messages = response.messages else {return}
                self.pageToken["temp"] = response.nextPageToken ?? "end"
                if next {
                    let mailViewModels = messages.map({ (message) -> MailViewModel in
                        return MailViewModel(message: message, infoAction: {
                            guard let html = message.payload?.html else { return }
                            self.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
                        }, sectionTitle: "Mail", sectionImage: #imageLiteral(resourceName: "suggestionsMail"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
                    })
                    self.dataSource.append(mailViewModels)
                    
                } else {
                    let mailViewModels = messages.map({ (message) -> MailViewModel in
                        return MailViewModel(message: message, infoAction: {
                            guard let html = message.payload?.html else { return }
                            self.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
                        }, sectionTitle: "Mail", sectionImage: #imageLiteral(resourceName: "suggestionsMail"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
                    })
                    
                    
                    self.dataSource = [mailViewModels]
                }
            }
        }
    }
    
    private func selectCollectionViewForConnectedMail(){
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            
            self.dataSource.enumerated().forEach({ (section, collectionDatas) in
                collectionDatas.enumerated().forEach({ (item, collectionData) in
                    guard let mailViewModel = collectionData as? MailViewModel,
                        let identifier = mailViewModel.message.identifier else { return }
                    if self.note.mailIdentifiers.contains(identifier) {
                        let indexPath = IndexPath(item: item, section: section)
                        DispatchQueue.main.async {
                            self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
                        }
                    }
                })
            })
            
        }
    }
    
    private func requestLogin() {
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
    
    private func requestMessage(_ indexPath: IndexPath, _ completion: ((GTLRGmail_Message) -> ())? = nil) {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self,
                let user = GIDSignIn.sharedInstance().currentUser,
                let identifier = (self.dataSource[indexPath.section][indexPath.item] as? MailViewModel)?.message.identifier else { return }

            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: user.userID, identifier: identifier)
            
            self.service.executeQuery(query) { (ticket, response, error) in
                guard let response = response as? GTLRGmail_Message else {return}
                
                self.cachedData[indexPath] = response
                
                DispatchQueue.main.async {
                    completion?(response)
                }

            }
        }
    }
    
    
}

extension MailPickerCollectionViewController : UICollectionViewDataSourcePrefetching {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //아직 데이터가 완전하지 않음
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.identifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell

        if let message = cachedData[indexPath] {
            let viewModel = MailViewModel(message: message, infoAction: {
                guard let html = message.payload?.html else { return }
                self.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
            }, sectionTitle: "Mail".loc, sectionImage: #imageLiteral(resourceName: "suggestionsMail"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
            cell.data = viewModel
        } else {
            requestMessage(indexPath) { (message) in
                let viewModel = MailViewModel(message: message, infoAction: {
                    guard let html = message.payload?.html else { return }
                    self.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
                }, sectionTitle: "Mail".loc, sectionImage: #imageLiteral(resourceName: "suggestionsMail"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
                cell.data = viewModel
            }
        }
        
        
        cell.data = data
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            if cachedData[$0] == nil {
                requestMessage($0)
            }
        }
        
//        var sum = 0
//        dataSource.enumerated().forEach { (offset, datas) in
//            sum += (offset + 1) * datas.count
//        }
//
//        guard let lastIndex = indexPaths.last else { return }
//
//        var current = 0
//        for i in 0 ... lastIndex.section {
//            (i + 1) * 
//            
//        }
//
//
//        guard let lastIndex = , lastIndex >= data
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? DetailCollectionReusableView.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = dataSource[indexPath.section][indexPath.item]
        return reusableView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource[section].first?.headerSize ?? CGSize.zero
    }
}

extension MailPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? MailViewModel, let identifier = viewModel.message.identifier else { return }
        
        if let index = identifiersToDelete.index(of: identifier) {
            identifiersToDelete.remove(at: index)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? MailViewModel,
            let identifier = viewModel.message.identifier else { return }
        
        if note.mailIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension MailPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maximumWidth = collectionView.bounds.width - (collectionView.marginLeft + collectionView.marginRight)
        return dataSource[indexPath.section][indexPath.item].size(maximumWidth: maximumWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
