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

extension CNContact: Collectionable {
    func size(view: View) -> CGSize {
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        let nameHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let numHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption1)]).size().height
        let mailHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption1)]).size().height
        let margin: CGFloat = 8
        let spacing: CGFloat = 4
        let totalHeight = nameHeight + numHeight + mailHeight + margin * 2 + spacing * 2
        var cellCount: CGFloat = 3
        if safeWidth > 414 {
            let widthOne = (safeWidth - (cellCount + 1) * margin) / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = (safeWidth - (cellCount + 1) * margin) / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        cellCount = 1
        return CGSize(width: (safeWidth - (cellCount + 1) * margin), height: totalHeight)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        let contactVC = CNContactViewController(for: self)
        let contactStore = CNContactStore()
        contactVC.allowsEditing = true
        contactVC.contactStore = contactStore
        viewController.navigationController?.pushViewController(contactVC, animated: true)
    }
}


struct ContactViewModel: ViewModel {
    let cnContact: CNContact
    init(cnContact: CNContact) {
        self.cnContact = cnContact
    }
}

class CNContactCell: UICollectionViewCell, ViewModelAcceptable {
    
    var viewModel: ViewModel? {
        didSet {
            guard let contactViewModel = self.viewModel as? ContactViewModel else { return }
            let cnContact = contactViewModel.cnContact
            nameLabel.text = cnContact.familyName + " " + cnContact.givenName
            phoneNumLabel.text = cnContact.phoneNumbers.first?.value.stringValue ?? "휴대폰 정보 없음"
            mailLabel.text = cnContact.emailAddresses.first?.value as String? ?? "메일 정보 없음"
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        view.cornerRadius = 15
        return view
    }
}
