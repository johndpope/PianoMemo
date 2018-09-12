//
//  DetailInputView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit
import Contacts
import Photos

public enum InputType {
    case connect
    case recommend
}

class DetailInputView: UIView {
    /**
     여기에 type만 세팅해주면 자동으로 바뀜
    */
    public var type: InputType? {
        didSet {
            reset()

            guard let type = self.type else { return }
            switch type {
            case .connect:
                setConnect()
            case .recommend:
                setRecommend()
            }
        }
    }
    weak var detailVC: DetailViewController?
    private var dataSource: [[CollectionDatable]] = []
    @IBOutlet weak var collectionView: UICollectionView!

    private lazy var eventStore = EKEventStore()
    private lazy var contactStore = CNContactStore()
    private lazy var imageManager = PHCachingImageManager()
    
    
    var note: Note? {
        guard let detailVC = detailVC else { return nil }
        return detailVC.note
    }


}



//MARK: Action
extension DetailInputView {
    @IBAction func add(_ sender: Any) {
        detailVC?.fakeTextField.resignFirstResponder()
        presentActionSheet()
    }

    @IBAction func close(_ sender: Any) {
        // 리셋시키고, 텍스트필드 인풋뷰 초기화하기
        type = nil
        detailVC?.fakeTextField.resignFirstResponder()
    }
}

extension DetailInputView {
    private func alert() {
        let alert = UIAlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        detailVC?.present(alert, animated: true)
    }

    private func presentActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let reminder =  UIAlertAction(title: "미리알림", style: .default) { [weak self] (_) in
            self?.detailVC?.performSegue(withIdentifier: ReminderPickerCollectionViewController.identifier, sender: nil)
        }

        let event = UIAlertAction(title: "캘린더", style: .default) { [weak self] (_) in
            self?.detailVC?.performSegue(withIdentifier: EventPickerCollectionViewController.identifier, sender: nil)
        }

        let contact = UIAlertAction(title: "연락처", style: .default) { [weak self] (_) in
            self?.detailVC?.performSegue(withIdentifier: ContactPickerCollectionViewController.identifier, sender: nil)
        }

        let photo = UIAlertAction(title: "사진", style: .default) { [weak self] (_) in
            self?.detailVC?.performSegue(withIdentifier: PhotoPickerCollectionViewController.identifier, sender: nil)
        }

        let mail = UIAlertAction(title: "메일", style: .default) { [weak self] (_) in
            self?.detailVC?.performSegue(withIdentifier: MailPickerCollectionViewController.identifier, sender: nil)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(reminder)
        alertController.addAction(event)
        alertController.addAction(contact)
        alertController.addAction(photo)
        alertController.addAction(mail)
        alertController.addAction(cancel)


        detailVC?.present(alertController, animated: true, completion: nil)
    }
}


extension DetailInputView {
    private func reset() {
        dataSource = []
        collectionView.reloadData()
    }

    private func setConnect() {
        //지울 거 있으면 지우기
        
        note?.deleteLosedIdentifiers(eventStore: eventStore, contactStore: contactStore)

        appendRemindersToDataSource()
        appendEventsToDataSource()
        appendContactsToDataSource()
        appendPhotosToDataSource()
        appendMailsToDataSource()

        collectionView.reloadData()
    }

    private func setRecommend() {


    }

    private func appendRemindersToDataSource() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            eventStore.requestAccess(to: .reminder) { [weak self] (status, error) in
                switch status {
                case true: self?.fetchReminders()
                case false: self?.alert()
                }
            }

        case .authorized: fetchReminders()
        case .restricted, .denied: alert()
        }
    }

    private func appendEventsToDataSource() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            eventStore.requestAccess(to: .event) { [weak self] (status, error) in
                switch status {
                case true : self?.fetchEvents()
                case false: self?.alert()
                }
            }
        case .authorized: fetchEvents()
        case .restricted, .denied: alert()
        }
    }

    private func appendContactsToDataSource() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { [weak self] (status, error) in
                switch status {
                case true: self?.fetchContacts()
                case false: self?.alert()
                }
            }
        case .authorized: fetchContacts()
        case .restricted, .denied: alert()
        }
    }

    private func appendPhotosToDataSource() {

        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                switch status {
                case .authorized:
                    self?.fetchPhotos()
                default:
                    self?.alert()
                }
            }
        case .authorized: fetchPhotos()
        default: alert()
        }
    }
    
    private func appendMailsToDataSource() {
        fetchMails()
    }

    private func fetchReminders() {
        guard let reminderCollection = note?.reminderCollection else { return }
        var reminderViewModels: [ReminderViewModel] = []

        reminderCollection.forEach { (value) in
            guard let reminder = value as? Reminder,
                let identifier = reminder.identifier else { return }

            if let ekReminder = eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKReminder {
                let reminderViewModel = ReminderViewModel(reminder: ekReminder)
                reminderViewModels.append(reminderViewModel)
                return
            }
        }

        dataSource.append(reminderViewModels)
    }

    private func fetchEvents() {
        guard let eventCollection = note?.eventCollection else { return }
        var eventViewModels: [EventViewModel] = []

        eventCollection.forEach { (value) in
            guard let event = value as? Event,
                let identifier = event.identifier else { return }

            if let ekEvent = eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKEvent {
                let eventViewModel = EventViewModel(event: ekEvent)
                eventViewModels.append(eventViewModel)
                return
            }
        }

        dataSource.append(eventViewModels)
    }

    private func fetchContacts() {
        guard let contactCollection = note?.contactCollection else { return }
        var contactViewModels: [ContactViewModel] = []

        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]

        contactCollection.forEach { (value) in
            guard let contact = value as? Contact,
                let identifier = contact.identifier else { return }

            do {
                let cnContact = try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
                let contactViewModel = ContactViewModel(contact: cnContact, contactStore: contactStore)
                contactViewModels.append(contactViewModel)
                return
            } catch {
                print("in: fetchContacts 연락처가 가져와지지 않아요. : \(error.localizedDescription) ")
            }
        }
        dataSource.append(contactViewModels)
    }

    private func fetchPhotos() {
        guard let photoCollection = note?.photoCollection else { return }
        var photoViewModels: [PhotoViewModel] = []
        let identifiers = photoCollection.compactMap { (value) -> String? in
            guard let photo = value as? Photo,
                let identifier = photo.identifier else {return nil }
            return identifier
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        guard assets.count != 0 else { return }
        for i in 0 ... assets.count - 1 {
            let asset = assets.object(at: i)
            let minLength = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            let minimumSize = CGSize(width: minLength / 4, height: minLength / 4)
            let photoViewModel = PhotoViewModel(asset: asset,
                                                imageManager: imageManager ,
                                                minimumSize: minimumSize)
            photoViewModels.append(photoViewModel)
        }


        dataSource.append(photoViewModels)
    }

    private func fetchMails() {
        guard let mailCollection = note?.mailCollection else { return }
        var mailViewModels: [MailViewModel] = []

        mailCollection.forEach { (value) in
            guard let mail = value as? Mail else { return }
            let mailViewModel = MailViewModel(mail: mail)
            mailViewModels.append(mailViewModel)
        }

        mailViewModels.sort { (a, b) -> Bool in
            guard let aDate = a.mail.date,
                let bDate = b.mail.date else { return true }
            return aDate > bDate
        }

        dataSource.append(mailViewModels)
    }
}

extension DetailInputView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.identifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
        cell.data = data
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? "DetailIVCollectionReusableView", for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
//        reusableView.data = dataSource[indexPath.section][indexPath.item]
//        return reusableView
//    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return dataSource[section].first?.headerSize ?? CGSize.zero
//    }
}

extension DetailInputView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let detailVC = detailVC else { return }
        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: detailVC)
    }
}

extension DetailInputView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset ?? UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maximumWidth = collectionView.bounds.width - (collectionView.marginLeft + collectionView.marginRight)
        return dataSource[indexPath.section][indexPath.item].size(maximumWidth: maximumWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }

}
