//
//  MailCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

struct MailViewModel: CollectionDatable {
    let message: GTLRGmail_Message?
    let identifier: String?
    let detailAction: (() -> Void)?
    var sectionTitle: String?
    var sectionImage: Image?
    var sectionIdentifier: String?
    
    init(message: GTLRGmail_Message? = nil, identifier: String? = nil, detailAction: (() -> Void)? = nil, sectionTitle: String, sectionImage: Image, sectionIdentifier: String) {
        self.message = message
        self.identifier = identifier
        self.detailAction = detailAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    var headerSize: CGSize {
        return CGSize(width: 100, height: 40)
    }
    
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
//    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return detailAction != nil ? CGSize(width: maximumWidth, height: 140) : CGSize(width: maximumWidth, height: 107)
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        if let vc = viewController as? DetailViewController,
            let html = message?.payload?.html {
            
            print(message?.payload?.json ?? "nil")
            vc.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
}

class MailViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? MailViewModel else { return }
            
            if let selectedView = selectedBackgroundView {
                insertSubview(selectedView, aboveSubview: detailButton)
            }
            
            detailButton.isHidden = viewModel.detailAction == nil
            
            
            if let payload = viewModel.message?.payload {
                nameLabel.text = payload.from
                subjectLabel.text = payload.headers?.first(where: {$0.name == "Subject"})?.value
                snippetLabel.text = viewModel.message?.snippet
                if let dateStr = payload.headers?.first(where: {$0.name == "Date"})?.value,
                    let date = (dateStr.dataDetector as? Date){
                    dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                } else {
                    dateLabel.text = DateFormatter.sharedInstance.string(from: Date())
                }
                detailButton.isHidden = true
                return
            } else {
                requestMessage()
            }
            
            
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
    
//    var message: GTLRGmail_Message?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = borderView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = ""
        dateLabel.text = ""
        subjectLabel.text = ""
        snippetLabel.text = ""
    }
    
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color.clear
        view.cornerRadius = 15
        view.borderWidth = 2
        view.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
        return view
    }
    
    @IBAction func detail(_ sender: Any) {
        guard let viewModel = self.data as? MailViewModel,
            let detailAction = viewModel.detailAction else { return }
        detailAction()
    }
    
    private func requestMessage() {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self,
                let user = GIDSignIn.sharedInstance().currentUser,
                let viewModel = (self.data as? MailViewModel),
                let identifier = viewModel.identifier else { return }
            
            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: user.userID, identifier: identifier)
            let service = GTLRGmailService()
            service.authorizer = user.authentication.fetcherAuthorizer()
            service.executeQuery(query) { (ticket, response, error) in
                guard let message = response as? GTLRGmail_Message else {return}
                
                let mailViewModel = MailViewModel(message: message, sectionTitle: "Mail".loc, sectionImage: #imageLiteral(resourceName: "suggestionsMail"), sectionIdentifier: PianoCollectionReusableView.reuseIdentifier)
                self.data = mailViewModel
                
                DispatchQueue.main.async {
                    guard let payload = message.payload else { return }
                    
                    self.nameLabel.text = payload.from
                    self.subjectLabel.text = payload.headers?.first(where: {$0.name == "Subject"})?.value
                    self.snippetLabel.text = message.snippet
                    if let dateStr = payload.headers?.first(where: {$0.name == "Date"})?.value,
                        let date = DateFormatter.sharedInstance.date(from: dateStr){
                        self.dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                    }
                    
                }
                
            }
        }
    }
    
}
