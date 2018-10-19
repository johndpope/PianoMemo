//
//  TextAccessoryViewController.swift
//  Piano
//
//  Created by Kevin Kim on 01/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import ContactsUI
import CoreLocation

class TextAccessoryViewController: UIViewController, CollectionRegisterable {
    weak private var masterViewController: MasterViewController?
    weak var syncController: Synchronizable!
    var kbHeight: CGFloat = UIScreen.main.bounds.height / 3
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    let locationManager = CLLocationManager()
    var showDefaultTag: Bool = true

    private var collectionables: [[Collectionable]] = []
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if syncController == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.syncController = appDelegate.syncController
            }
        }
        
        registerCell(ImageTagModelCell.self)
        registerCell(TagModelCell.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotification()
        reloadCollectionView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
    }
    
    /**
     최초 세팅
     */
    internal func setup(masterViewController: MasterViewController) {
        self.masterViewController = masterViewController
    }
    
    /**
     이 놈을 호출하면 자동으로 갱신됨
     */
    internal func reloadCollectionView() {
        collectionables = []
        
        if showDefaultTag {
            let imageTagModels = Preference.defaultTags.map { return ImageTagModel(type: $0)}
            collectionables.append(imageTagModels)
        }
        
        let emojiTagModels = syncController.emojiTags.map { return TagModel(string: $0, isEmoji: true) }
        collectionables.append(emojiTagModels)
        collectionView.reloadData()
    }
    

}

extension TextAccessoryViewController {
    
    private func pasteClipboard() {
        guard let textView = masterViewController?.bottomView.textView else { return }
        textView.paste(nil)
    }
    
    private func setOneHourLater() {
        guard let textView = masterViewController?.bottomView.textView else { return }
        var text = ": "
        text.append(DateFormatter.sharedInstance.string(from: Date(timeInterval: 60 * 60 + 1, since: Date())))
        textView.insertText(text)
    }
    
    private func setOneDayLater() {
        guard let textView = masterViewController?.bottomView.textView else { return }
        var text = ""
        text.append(DateFormatter.sharedInstance.string(from: Date(timeInterval: 60 * 60 * 24 + 1, since: Date())))
        textView.insertText(text)
    }
    
    private func setCurrentLocation() {
        guard let vc = masterViewController,
            let textView = vc.bottomView.textView else { return }
        
        if textView.inputView != nil {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        Access.locationRequest(from: vc, manager: locationManager) { [weak self] in
            self?.lookUpCurrentLocation(completionHandler: {(placemark) in
                if let address = placemark?.postalAddress {
                    let str = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).split(separator: "\n").reduce("", { (str, subStr) -> String in
                        guard str.count != 0 else { return String(subStr) }
                        return (str + " " + String(subStr))
                    })
                    
                    textView.insertText(str)
                } else {
                    Alert.warning(from: vc, title: "GPS Error".loc, message: "Your device failed to get location.".loc)
                }
            })
            
        }
    }
    
    private func presentCurrentLocation() {
        guard let vc = masterViewController else { return }
        Access.locationRequest(from: vc, manager: locationManager) { [weak self] in
            self?.lookUpCurrentLocation(completionHandler: {(placemark) in
                if let address = placemark?.postalAddress {
                    
                    let mutableContact = CNMutableContact()
                    let postalValue = CNLabeledValue<CNPostalAddress>(label:CNLabelOther, value:address)
                    mutableContact.postalAddresses = [postalValue]
                    mutableContact.familyName = Preference.locationTags.reduce("", +)
                    
                    Access.contactRequest(from: vc) {
                        let contactStore = CNContactStore()
                        DispatchQueue.main.async {
                            let contactVC = CNContactViewController(forNewContact: mutableContact)
                            contactVC.contactStore = contactStore
                            contactVC.delegate = vc
                            let nav = UINavigationController()
//                            contactVC.displayedPropertyKeys = [CNContactPostalAddressesKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
//                            contactVC.highlightProperty(withKey: CNContactPhoneNumbersKey, identifier: CNLabelOther)
                            nav.viewControllers = [contactVC]
                            vc.present(nav, animated: true, completion: nil)
                        }
                    }
                    
                    
                } else {
                    Alert.warning(from: vc, title: "GPS Error".loc, message: "Your device failed to get location.".loc)
                }
            })
            
        }
    }
    
    private func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
        -> Void ) {
        // Use the last reported location.
        if let lastLocation = locationManager.location {
            let geocoder = CLGeocoder()
            
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                                            completionHandler: { (placemarks, error) in
                                                if error == nil {
                                                    let firstLocation = placemarks?[0]
                                                    completionHandler(firstLocation)
                                                }
                                                else {
                                                    // An error occurred during geocoding.
                                                    completionHandler(nil)
                                                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
}

extension TextAccessoryViewController {
    internal func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
    }
    
    @objc func pasteboardChanged() {
        let firstIndexPath = IndexPath(item: 0, section: 0)
        guard let cell = collectionView.cellForItem(at: firstIndexPath) as? ImageTagModelCell,
            let viewModel = collectionables[firstIndexPath.section][firstIndexPath.item] as? ViewModel else { return }
        cell.viewModel = viewModel
    }
    
    internal func unRegisterAllNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        self.kbHeight = kbHeight
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension TextAccessoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let collectionable = collectionables[indexPath.section][indexPath.item] as! Collectionable & ViewModel
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionable.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        cell.viewModel = collectionable
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionables[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionables.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
        return reusableView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section != 0 ? CGSize(width: 1, height: 30) : CGSize.zero
    }
    
}

//1. 유저가 태그 셀을 누를 때마다 마스터 바텀뷰 태그 레이블이 갱신된다.  2. 태그 레이블이 갱신되면(이전 값과 다르면), 마스터 뷰컨의 테이블 뷰도 갱신되어야 한다.

extension TextAccessoryViewController: UICollectionViewDelegate {

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //태그레이블에 넣어주거나, 화면을 띄우는 역할
        //TODO: 뷰모델 방식으로 다 바꿔야함
//        collectionables[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: viewController)

        //TODO: 구독모델일 때에는 이게 다이나믹해지므로 모델을 변경해서 적절한 행동을 호출하도록 해야함
        
        
        //section == 0이면 각각에 맞는 디폴트 행동 실행
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                pasteClipboard()
                if (UIPasteboard.general.string ?? "").count == 0 {
                    masterViewController?.transparentNavigationController?.show(message: "There's no text on Clipboard. 😅".loc, color: Color.trash)
                }
            } else if indexPath.item == 1 {
                setCurrentLocation()
            }
        } else {
            //section != 0이면 인서트
            guard let tagModel = collectionables[indexPath.section][indexPath.item] as? TagModel,
                let masterVC = masterViewController else {return }
            
            if masterVC.tagsCache.contains(tagModel.string) {
                masterVC.tagsCache.removeCharacters(strings: [tagModel.string])
                
            } else {
                masterVC.tagsCache = masterVC.tagsCache + tagModel.string
            }   
        }
        
        masterViewController?.requestQuery()
        collectionView.deselectItem(at: indexPath, animated: true)
        Feedback.success()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let vc = masterViewController else { return }
        collectionables[indexPath.section][indexPath.item].didDeselectItem(collectionView: collectionView, fromVC: vc)
    }
}

extension TextAccessoryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionables[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionables[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables[section].first?.minimumInteritemSpacing ?? 0
    }
}

//extension TextAccessoryViewController: CNContactPickerDelegate {
//    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self, let textView = self.textView else { return }
//
//            textView.selectedRange = self.selectedRange
//            textView.becomeFirstResponder()
//            self.selectedRange = NSMakeRange(0, 0)
//        }
//
//    }
//
//    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
//        CATransaction.setCompletionBlock { [weak self] in
//            guard let self = self, let textView = self.textView else { return }
//
//            textView.selectedRange = self.selectedRange
//            textView.becomeFirstResponder()
//
//            //TODO: 언어 판별해서 name 순서 바꿔주기(공백 유무도)
//            //contains
//            //Japanese
//            //Chinese
//            //Korean
//            let westernStyle = contact.givenName + " " + contact.familyName
//            let easternStyle = contact.familyName + contact.givenName
//            var str = ""
//            if let language = westernStyle.detectedLangauge(), language.contains("Japanese") || language.contains("Chinese") || language.contains("Korean") {
//                str = easternStyle
//            } else {
//                str = westernStyle
//            }
//
//            if let phone = contact.phoneNumbers.first?.value.stringValue {
//                str.append(" " + phone)
//            }
//
//            if let mail = contact.emailAddresses.first?.value as String? {
//                str.append(" " + mail)
//            }
//
//            str.append("\n")
//
//            textView.insertText(str)
//
//            self.selectedRange = NSMakeRange(0, 0)
//        }
//
//
//    }
//}
