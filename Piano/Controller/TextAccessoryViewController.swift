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
    weak private var viewController: (ViewController & TextViewType & CLLocationManagerDelegate)?
    var kbHeight: CGFloat = UIScreen.main.bounds.height / 3
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    let locationManager = CLLocationManager()
    var showDefaultTag: Bool = true

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
    internal func setup(textView: TextView, viewController: ViewController & TextViewType & CLLocationManagerDelegate, showDefaultTag: Bool = true) {
        self.textView = textView
        self.viewController = viewController
        self.showDefaultTag = showDefaultTag
    }
    
    /**
     이 놈을 호출하면 자동으로 갱신됨
     */
    internal func reloadCollectionView() {
        collectionables = []
        
        if showDefaultTag {
            let defaultTagModels = Preference.defaultTags.map { return TagModel(string: $0, isEmoji: false)}
            collectionables.append(defaultTagModels)
        }
        
        let emojiTagModels = Preference.emojiTags.map { return TagModel(string: $0, isEmoji: true) }
        collectionables.append(emojiTagModels)
        collectionView.reloadData()
    }
    
    @IBAction func tapEraseAll(_ sender: Any) {
        textView?.text = ""
        textView?.typingAttributes = Preference.defaultAttr
        textView?.insertText("")
    }
    

}

extension TextAccessoryViewController {

    //textviewExtension에 넣기
    internal func deleteAll() {
        guard let textView = textView,
            textView.selectedRange.location > 0,
            textView.isFirstResponder else { return }
    
        let location = textView.selectedRange.location - 1
        let wordRange = textView.layoutManager.range(ofNominallySpacedGlyphsContaining: location)
        print(wordRange)
        guard let textRange = wordRange.toTextRange(textInput: textView) else { return }
        textView.replace(textRange, withText: "")
//        textView.textStorage.replaceCharacters(in: wordRange, with: "")
//        textView.selectedRange.location -= wordRange.length
        
    }
    
    internal func pasteClipboard() {
        guard let textView = textView else { return }
        textView.paste(nil)
    }
    
    internal func pasteCurrentLocation() {
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
                    Alert.warning(from: vc, title: "GPS Error".loc, message: "Your device failed to get location.".loc)
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
        
        guard let vc = viewController, let textView = textView else { return }
        textView.setInset(contentInsetBottom: Preference.textViewInsetBottom)
        collectionView.collectionViewLayout.invalidateLayout()
        
        
        if let dynamicTextView = textView as? DynamicTextView, !dynamicTextView.isSelectable, let pianoControl = dynamicTextView.pianoControl, let detailVC = vc as? DetailViewController, let pianoView = detailVC.pianoView {
            detailVC.connect(pianoView: pianoView, pianoControl: pianoControl, textView: dynamicTextView)
            pianoControl.attach(on: textView)
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section != 0 ? CGSize(width: 1, height: 30) : CGSize.zero
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

        if indexPath.section == 0 {
            //section == 0이면 각각에 맞는 디폴트 행동 실행
            if indexPath.item == 0 {
                pasteClipboard()
            } else if indexPath.item == 1 {
                pasteCurrentLocation()
            }
            
        } else {
            //section != 0이면 인서트
            guard let tagModel = collectionables[indexPath.section][indexPath.item] as? TagModel,
                let textView = textView else { return }
            textView.insertText(tagModel.string)
            
        }
        
        
        //calendar와 reminder 빼고는 모두 deselect
        if indexPath != IndexPath(item: 3, section: 1) && indexPath != IndexPath(item: 4, section: 1) {
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
            //contains
            //Japanese
            //Chinese
            //Korean
            let westernStyle = contact.givenName + " " + contact.familyName
            let easternStyle = contact.familyName + contact.givenName
            var str = ""
            if let language = westernStyle.detectedLangauge(), language.contains("Japanese") || language.contains("Chinese") || language.contains("Korean") {
                str = easternStyle
            } else {
                str = westernStyle
            }
            
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
