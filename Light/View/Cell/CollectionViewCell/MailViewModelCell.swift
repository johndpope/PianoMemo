//
//  MailCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import GoogleAPIClientForREST

struct MailViewModel: CollectionDatable {
    let message: GTLRGmail_Message
    let infoAction: (() -> Void)?
    var sectionTitle: String?
    var sectionImage: Image?
    var sectionIdentifier: String?
    
    init(message: GTLRGmail_Message, infoAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage: Image? = nil, sectionIdentifier: String? = nil) {
        self.message = message
        self.infoAction = infoAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        guard let html = self.message.payload?.html else { return }
        
        
        if infoAction == nil {
            viewController.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return sectionIdentifier != nil ? CGSize(width: maximumWidth, height: 107) : CGSize(width: maximumWidth, height: 140)
    }
    
    var headerSize: CGSize {
        return CGSize(width: 100, height: 33)
    }
    
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
}

class MailViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? MailViewModel,
                let payload = viewModel.message.payload else { return }
            nameLabel.text = payload.from
            subjectLabel.text = payload.headers?.first(where: {$0.name == "Subject"})?.value
            snippetLabel.text = viewModel.message.snippet
            if let dateStr = payload.headers?.first(where: {$0.name == "Date"})?.value,
                let date = DateFormatter.sharedInstance.date(from: dateStr){
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            }
            
            if let selectedView = selectedBackgroundView,
                viewModel.infoAction != nil {
                insertSubview(selectedView, aboveSubview: infoButton)
            }
//            infoButton.isHidden = viewModel.infoAction == nil
            descriptionView.isHidden = viewModel.sectionIdentifier != nil
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var descriptionView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = borderView
    }
    
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color.clear
        view.cornerRadius = 15
        view.borderWidth = 2
        view.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
        return view
    }
    
    @IBAction func info(_ sender: Any) {
        guard let viewModel = self.data as? MailViewModel,
            let infoAction = viewModel.infoAction else { return }
        infoAction()
    }
    
}
