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
    let detailAction: (() -> Void)?
    var sectionImage: Image?
    var sectionTitle: String?
    var sectionIdentifier: String?
    let contactStore: CNContactStore
    
    init(contact: CNContact, detailAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage: Image? = nil, sectionIdentifier: String? = nil, contactStore: CNContactStore) {
        self.contact = contact
        self.detailAction = detailAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
        self.contactStore = contactStore
    }
    
    var headerSize: CGSize {
        return sectionTitle != nil ? CGSize(width: 100, height: 40) : CGSize(width: 100, height: 0)
    }
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
    
    func didSelectItem(fromVC viewController: ViewController) {
        
        if detailAction == nil {
            let contactVC = CNContactViewController(for: self.contact)
            contactVC.view.backgroundColor = UIColor.white
            contactVC.allowsEditing = true
            contactVC.contactStore = self.contactStore
            viewController.navigationController?.pushViewController(contactVC, animated: true)
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
    
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return detailAction != nil ? CGSize(width: maximumWidth, height: 103) : CGSize(width: maximumWidth, height: 73)
    }
}

class ContactViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? ContactViewModel else { return }
            nameLabel.text = viewModel.contact.familyName + " " + viewModel.contact.givenName

            phoneNumLabel.text = viewModel.contact.phoneNumbers.first?.value.stringValue ?? "휴대폰 정보 없음"
            mailLabel.text = viewModel.contact.emailAddresses.first?.value as String? ?? "메일 정보 없음"
            
            if let selectedView = selectedBackgroundView {
                insertSubview(selectedView, aboveSubview: detailButton)
            }
            
            //나중에 디테일 보여줘야할 때 이부분 수정해야함
            detailButton.isHidden = true
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
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
    
    @IBAction func detail(_ sender: Any) {
        guard let viewModel = self.data as? ContactViewModel,
            let detailAction = viewModel.detailAction else { return }
        detailAction()
    }
}
