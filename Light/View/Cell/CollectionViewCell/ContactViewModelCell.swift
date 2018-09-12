//
//  ContactCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

struct ContactViewModel: CollectionDatable {
    let contact: CNContact
    let infoAction: (() -> Void)?
    var sectionImage: Image?
    var sectionTitle: String?
    var sectionIdentifier: String?
    let contactStore: CNContactStore
    
    init(contact: CNContact, infoAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage: Image? = nil, sectionIdentifier: String? = nil, contactStore: CNContactStore) {
        self.contact = contact
        self.infoAction = infoAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
        self.contactStore = contactStore
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        
        if infoAction == nil {
            let contactVC = CNContactViewController(for: self.contact)
            contactVC.allowsEditing = false
            contactVC.contactStore = self.contactStore
            viewController.navigationController?.pushViewController(contactVC, animated: true)
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
    
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return CGSize(width: maximumWidth, height: 100)
    }
    
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
}

class ContactViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? ContactViewModel else { return }
            nameLabel.text = viewModel.contact.familyName + " " + viewModel.contact.givenName
            
            
            phoneNumLabel.text = viewModel.contact.phoneNumbers.first?.value.stringValue ?? "휴대폰 정보 없음"
            
            mailLabel.text = viewModel.contact.emailAddresses.first?.label ?? "메일 정보 없음"
            
            infoButton.isHidden = viewModel.infoAction == nil
            
            if let selectedView = selectedBackgroundView,
                let viewModel = data as? ContactViewModel,
                viewModel.infoAction != nil {
                insertSubview(selectedView, aboveSubview: infoButton)
            }
            
            descriptionView.isHidden = viewModel.sectionIdentifier != nil
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
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
        guard let viewModel = self.data as? ContactViewModel,
            let infoAction = viewModel.infoAction else { return }
        infoAction()
    }
}
