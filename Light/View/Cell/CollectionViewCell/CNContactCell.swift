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

extension CNContact: CollectionDatable {
    var sectionImage: Image? { return #imageLiteral(resourceName: "suggestionsContact") }
    var sectionTitle: String? { return "Contact".loc }
    var headerSize: CGSize { return CGSize(width: 100, height: 40) }
    
    func size(view: View) -> CGSize {
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        let nameHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let numHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption1)]).size().height
        let mailHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption1)]).size().height
        let margin: CGFloat = 16 * 2
        let spacing: CGFloat = 4 * 2
        let totalHeight = nameHeight + numHeight + mailHeight + margin + spacing
        if safeWidth > 414 {
            var cellCount: CGFloat = 3
            let widthOne = safeWidth / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = safeWidth / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        
        return CGSize(width: safeWidth, height: totalHeight)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        let contactVC = CNContactViewController(for: self)
        let contactStore = CNContactStore()
        contactVC.allowsEditing = true
        contactVC.contactStore = contactStore
        viewController.navigationController?.pushViewController(contactVC, animated: true)
    }
}

class CNContactCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let cnContact = self.data as? CNContact else { return }
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
}
