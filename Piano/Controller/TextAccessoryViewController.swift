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
import MobileCoreServices
import DifferenceKit
import CoreData

class TextAccessoryViewController: UIViewController, CollectionRegisterable {
    weak private var masterViewController: MasterViewController?
    weak var writeService: Writable!
    var kbHeight: CGFloat = UIScreen.main.bounds.height / 3
    internal var selectedRange: NSRange = NSRange(location: 0, length: 0)
    let locationManager = CLLocationManager()
    var showDefaultTag: Bool = true
    private var selectedEmoji = ""
    private var models = [ArraySection<Model, TagModel>]()
    private var emojiTags: [TagModel] {
        return models[1].elements
    }
    private var managedObjectContext: NSManagedObjectContext {
        switch writeService {
        case .some(let service):
            return service.backgroundContext
        case .none:
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            return appDelegate.syncCoordinator.syncContext
        }
    }

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(ImageTagModelCell.self)
        registerCell(TagModelCell.self)
        registerFooterView(SeparatorReusableView.self)
        setupCollectionView()
    }

    enum Model: Differentiable {
        case image, emoji
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerAllNotification()
    }

    /**
     최초 세팅
     */
    internal func setup(masterViewController: MasterViewController) {
        self.masterViewController = masterViewController
    }

    private func setupCollectionView() {
        collectionView.dragDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.clipsToBounds = false
        models = newModels()
        collectionView.reloadData()
    }

    @objc private func refreshCollectionView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let changeSet = StagedChangeset(source: self.models, target: self.newModels())

            self.collectionView.reload(using: changeSet) { (data) in
                self.models = data
            }

            guard self.collectionView.indexPathsForSelectedItems == nil else { return }
            if let item = self.emojiTags.firstIndex(where: { emoji -> Bool in
                return emoji.string == self.selectedEmoji
            }) {
                let indexPath = IndexPath(item: item, section: 1)
                self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        }
    }

    func deselectAll() {
        selectedEmoji = ""
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
    }

    private func newModels() -> [ArraySection<Model, TagModel>] {
        func newEmojiTags() -> [TagModel] {
            return KeyValueStore.default.emojis
                .sorted(by: managedObjectContext.emojiSorter)
                .map { return TagModel(string: $0, isEmoji: true) }
        }
        var models = [ArraySection<Model, TagModel>]()
        let imageTagSection = [
            TagModel(string: "clipboard", isEmoji: false),
            TagModel(string: "schedule", isEmoji: false),
            TagModel(string: "location", isEmoji: false)
        ]
        models.append(ArraySection(model: Model.image, elements: imageTagSection))
        models.append(ArraySection(model: Model.emoji, elements: newEmojiTags()))
        return models
    }
}

extension TextAccessoryViewController {

    private func pasteClipboard() {
        guard let textView = masterViewController?.bottomView.textView else { return }
        if UIPasteboard.general.hasStrings {
            textView.paste(nil)
        } else {
            masterViewController?.transparentNavigationController?.show(message: "There's no text on Clipboard. 😅".loc, textColor: Color.white, color: Color.redNoti)
        }

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
                    let postalValue = CNLabeledValue<CNPostalAddress>(label: CNLabelOther, value: address)
                    mutableContact.postalAddresses = [postalValue]

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
                                                } else {
                                                    // An error occurred during geocoding.
                                                    completionHandler(nil)
                                                }
            })
        } else {
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshCollectionView),
            name: .refreshTextAccessory,
            object: nil
        )
    }

    @objc func pasteboardChanged() {
        let firstIndexPath = IndexPath(item: 0, section: 0)
        guard let cell = collectionView.cellForItem(at: firstIndexPath) as? ImageTagModelCell else { return }
        cell.imageView.image = UIPasteboard.general.hasStrings ? #imageLiteral(resourceName: "fullClipboard") : #imageLiteral(resourceName: "clipboard")
    }

    internal func unRegisterAllNotification() {
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

        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageTagModelCell.reuseIdentifier, for: indexPath) as! ImageTagModelCell
            switch indexPath.item {
            case 0:
                cell.viewModel = ImageTagModel(type: .clipboard)
            case 1:
                cell.viewModel = ImageTagModel(type: .schedule)
            case 2:
                cell.viewModel = ImageTagModel(type: .location)
            default:
                ()
            }

            return cell
        } else {
            let tag = emojiTags[indexPath.item]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tag.reuseIdentifier, for: indexPath) as! TagModelCell
            cell.viewModel = tag
            return cell

        }

    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return emojiTags.count
        }

    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if indexPath.section == 0 {
            let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeparatorReusableView.reuseIdentifier, for: indexPath)
            return reusableView
        } else {
            let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AddTagReusableView.reuseIdentifier, for: indexPath) as! AddTagReusableView
            reusableView.button.isHidden = false
            reusableView.backgroundColor = .white
            reusableView.action = { [weak self] in
                self?.masterViewController?.unRegisterAllNotification()
                self?.masterViewController?.performSegue(withIdentifier: TagPickerViewController.identifier, sender: nil)
            }
            return reusableView
        }

    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return section != 0 ? CGSize(width: 1, height: 30) : CGSize.zero
//    }
//    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return section != 0 ? CGSize(width: 46, height: 30) : CGSize(width: 0.3, height: 30)
    }

}

//1. 유저가 태그 셀을 누를 때마다 마스터 바텀뷰 태그 레이블이 갱신된다.  2. 태그 레이블이 갱신되면(이전 값과 다르면), 마스터 뷰컨의 테이블 뷰도 갱신되어야 한다.

extension TextAccessoryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch indexPath.item {
            case 0:
                pasteClipboard()
            case 1:
                guard let vc = masterViewController else { return }
                Access.reminderRequest(from: vc) {
                    Access.eventRequest(from: vc, success: {
                        DispatchQueue.main.async {
                            vc.performSegue(withIdentifier: ScheduleViewController.identifier, sender: nil)
                        }
                    })
                }

            case 2:
                setCurrentLocation()
            default:
                ()
            }
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        guard let masterVC = masterViewController else { return }
        let tagModel = emojiTags[indexPath.item]

        if masterVC.tagsCache.contains(tagModel.string) {
            masterVC.tagsCache.removeCharacters(strings: [tagModel.string])

        } else {
            masterVC.tagsCache = masterVC.tagsCache + tagModel.string
        }
        selectedEmoji = tagModel.string
        masterVC.requestFilter()

        masterVC.bottomView.eraseButton.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0) != 0 || masterVC.bottomView.textView.text.count != 0
        Feedback.success()
        refreshDragState()
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {

        guard let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems else { return true }

        if indexPathsForSelectedItems.contains(indexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
            collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
            return false
        }

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let masterVC = masterViewController else { return }
        let tagModel = emojiTags[indexPath.item]

        if masterVC.tagsCache.contains(tagModel.string) {
            masterVC.tagsCache.removeCharacters(strings: [tagModel.string])

        } else {
            masterVC.tagsCache = masterVC.tagsCache + tagModel.string
        }
        selectedEmoji = ""
        masterVC.requestFilter()
        masterVC.bottomView.eraseButton.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0) != 0 || masterVC.bottomView.textView.text.count != 0
        Feedback.success()
        refreshDragState()
    }

    private func refreshDragState() {
        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count > 1 {
            collectionView.dragInteractionEnabled = false
        } else {
            collectionView.dragInteractionEnabled = true
        }
    }
}

extension TextAccessoryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
//        return tagModels.first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return indexPath.section == 0 ? CGSize(width: 50, height: 46) : (emojiTags.first?
            .size(view: collectionView) ?? CGSize.zero)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return emojiTags.first?.minimumLineSpacing ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return emojiTags.first?.minimumInteritemSpacing ?? 0
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

extension TextAccessoryViewController: UICollectionViewDragDelegate {

    private func draggingModel(indexPath: IndexPath) -> TagModel? {
        return emojiTags[indexPath.item]
    }

    private func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        guard let model = draggingModel(indexPath: indexPath) else { return [] }
        let nsString = NSString(string: model.string)
        let itemProvider = NSItemProvider(object: nsString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = nsString
        return [dragItem]
    }

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath) -> [UIDragItem] {

        if let cell = collectionView.cellForItem(at: indexPath) as? TagModelCell {
            cell.setSizeState(.large)
            Feedback.success()
            return dragItems(for: indexPath)
        } else {
            return []
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {

        if let cell = collectionView.cellForItem(at: indexPath) as? TagModelCell,
            let attributedText = cell.label.attributedText {

            let parameters = UIDragPreviewParameters()
            let offset = cell.label.frame.origin.x
            let rect = CGRect(origin: CGPoint(x: offset, y: 0), size: attributedText.size())
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(roundedRect: rect, cornerRadius: 10)
            return parameters
        }
        return nil
    }
}
