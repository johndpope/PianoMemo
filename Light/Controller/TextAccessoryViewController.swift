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
    weak private var textView: TextView?
    weak private var viewController: (ViewController & InputViewChangeable & CLLocationManagerDelegate)?
    var kbHeight: CGFloat = UIScreen.main.bounds.height / 3
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    let locationManager = CLLocationManager()

    private var collectionables: [[Collectionable]] = []
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
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
    internal func setup(textView: TextView, viewController: ViewController & InputViewChangeable & CLLocationManagerDelegate) {
        self.textView = textView
        self.viewController = viewController
    }
    
    /**
     이 놈을 호출하면 자동으로 갱신됨
     */
    internal func reloadCollectionView() {
        collectionables = []
        let customTagModels = Preference.customTags.map { return TagModel(string: $0) }
        let defaultTagModels = Preference.defaultTags.map { return TagModel(string: $0)}
        collectionables.append(customTagModels)
        collectionables.append(defaultTagModels)
        collectionView.reloadData()
    }

}

extension TextAccessoryViewController {
    internal func setInputViewForCalendar() {
        guard let vc = viewController,
            let textView = textView,
            let textInputView = vc.textInputView else { return }
        
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
        
        
        
//        textInputView.frame.size.height = self.kbHeight
//        textView.inputView = textInputView
//        textView.reloadInputViews()
//        textInputView.dataType = .event
//        textView.becomeFirstResponder()
        
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            textInputView.bounds.size.height = self.kbHeight
            textView.inputView = textInputView
            textView.reloadInputViews()
            textInputView.dataType = .event
        }
    }
    
    internal func setInputViewForNil(){
        guard let textView = textView else { return }
        textView.inputView = nil
        textView.reloadInputViews()
    }
    
    internal func setInputViewForReminder() {
        guard let vc = viewController,
            let textView = textView,
            let textInputView = vc.textInputView else { return }
        
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
        
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            textInputView.frame.size.height = self.kbHeight
            textView.inputView = textInputView
            textView.reloadInputViews()
            textInputView.dataType = .reminder
        }
    }
    
    internal func setContactPicker() {
        guard let vc = viewController,
            let textView = textView else { return }
        
        if textView.inputView != nil {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        let contactPickerVC = CNContactPickerViewController()
        contactPickerVC.delegate = self
        selectedRange = textView.selectedRange
        vc.present(contactPickerVC, animated: true, completion: nil)
    }
    
    internal func setCurrentTime() {
        guard let textView = textView else { return }
        
        if textView.inputView != nil {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        textView.insertText(DateFormatter.longSharedInstance.string(from: Date()))
    }
    
    internal func setCurrentLocation() {
        guard let vc = viewController,
            let textView = textView else { return }
        
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
                    Alert.warning(from: vc, title: "GPS 오류".loc, message: "디바이스가 위치를 가져오지 못하였습니다.".loc)
                }
            })
            
        }
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
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
        hideKeyboard()
        
        guard let vc = viewController, let textView = textView else { return }
        vc.textInputView.collectionView.collectionViewLayout.invalidateLayout()
        textView.setInset(contentInsetBottom: Preference.textViewInsetBottom)
        
        vc.textInputView.collectionView.collectionViewLayout.invalidateLayout()
        collectionView.collectionViewLayout.invalidateLayout()
        
        
        if let dynamicTextView = textView as? DynamicTextView, !dynamicTextView.isSelectable, let pianoControl = dynamicTextView.pianoControl, let detailVC = vc as? DetailViewController, let pianoView = detailVC.pianoView {
            detailVC.connect(pianoView: pianoView, pianoControl: pianoControl, textView: dynamicTextView)
            pianoControl.attach(on: textView)
        }
        
    }
    
    private func hideKeyboard() {
        //TODO: 화면 회전하면 일부로 키보드를 꺼서 키보드 높이에 input뷰가 적응하게 만든다. 그리고 플러스 버튼을 리셋시키기 위한 코드
        guard let textView = textView else { return }
        textView.inputView = nil
        textView.reloadInputViews()
        CATransaction.setCompletionBlock {
            textView.resignFirstResponder()
        }
        
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: false)
        }
    }
}

extension TextAccessoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let collectionable = collectionables[indexPath.section][indexPath.item] as! TagModel
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
}

extension TextAccessoryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let bool = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
        if bool {
            collectionView.deselectItem(at: indexPath, animated: true)
            textView?.inputView = nil
            textView?.reloadInputViews()
        }
        
        return !bool
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = viewController else { return }
        collectionables[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: viewController)
        
        
        
        //section == 0이면 맨 앞에 인서트
        if indexPath.section == 0 {
            guard let tagModel = collectionables[indexPath.section][indexPath.item] as? TagModel,
                let textView = textView else { return }
            
            
            let firstRange = NSMakeRange(0, 0)
            let beginning = textView.beginningOfDocument
            guard let start = textView.position(from: beginning, offset: firstRange.location),
                let end = textView.position(from: start, offset: firstRange.length),
                let textRange = textView.textRange(from: start, to: end) else { return }
            
            //맨 첫 문단에 bulletValue가 있다면, 개행을 삽입해주기
            var string = tagModel.string
            if BulletValue(text: textView.text, selectedRange: firstRange) != nil {
                string += "\n"
            }
            
            textView.replace(textRange, withText: string)
            
            
        } else {
            //section != 0이면 각각에 맞는 디폴트 행동 실행
            if indexPath.item == 0 {
                setCurrentLocation()
            } else if indexPath.item == 1 {
                setCurrentTime()
            } else if indexPath.item == 2 {
                setInputViewForCalendar()
            } else if indexPath.item == 3 {
                setInputViewForReminder()
            } else if indexPath.item == 4 {
                setContactPicker()
            }
            
        }
        
        
        //calendar와 reminder 빼고는 모두 deselect
        if indexPath != IndexPath(item: 2, section: 1) && indexPath != IndexPath(item: 3, section: 1) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let vc = viewController else { return }
        collectionables[indexPath.section][indexPath.item].didDeselectItem(collectionView: collectionView, fromVC: vc)
    }
}

extension TextAccessoryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionables.first?.first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionables[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables.first?.first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables.first?.first?.minimumInteritemSpacing ?? 0
    }
}

extension TextAccessoryViewController: CNContactPickerDelegate {
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let textView = self.textView else { return }
            
            textView.selectedRange = self.selectedRange
            textView.becomeFirstResponder()
            self.selectedRange = NSMakeRange(0, 0)
        }
        
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self, let textView = self.textView else { return }
            
            textView.selectedRange = self.selectedRange
            textView.becomeFirstResponder()
            
            //TODO: 언어 판별해서 name 순서 바꿔주기(공백 유무도)
            var str = "☎️ "
            str.append(contact.givenName + contact.familyName)
            
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                str.append(" " + phone)
            }
            
            if let mail = contact.emailAddresses.first?.value as String? {
                str.append(" " + mail)
            }
            
            str.append("\n")
            
            textView.insertText(str)
            
            self.selectedRange = NSMakeRange(0, 0)
        }
        
        
    }
}

extension MainViewController: CLLocationManagerDelegate {
    
}


