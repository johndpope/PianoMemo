//
//  DetailInputView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit
import ContactsUI
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
    let locationManager = CLLocationManager()
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
        detailVC?.view.endEditing(true)
        presentActionSheet()
    }

    @IBAction func close(_ sender: Any) {
        // 리셋시키고, 인풋뷰 초기화하기
        type = nil
        detailVC?.view.endEditing(true)
    }
}

extension DetailInputView {

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
        if let controller = alertController.popoverPresentationController,
            let detailVC = detailVC,
            UIDevice.current.userInterfaceIdiom == .pad {
            let frame = detailVC.view.frame
            controller.sourceView = detailVC.view
            controller.sourceRect = CGRect(x: frame.midX, y: frame.midY, width: 0, height: 0)
            controller.permittedArrowDirections = []
        }
        
        detailVC?.present(alertController, animated: true, completion: nil)
    }
}


extension DetailInputView {
    private func reset() {
        dataSource = []
        collectionView.reloadData()
        collectionView.contentOffset = CGPoint.zero
    }

    private func setConnect() {
        
        //TODO: 이걸 어떻게 처리할 지 고민하기, 사진의 경우에는 로컬만 되니 사진은 지우지 않는 걸로 처리하고, 
//        note?.deleteLosedIdentifiers(eventStore: eventStore, contactStore: contactStore)

        appendRemindersToDataSource()
        appendEventsToDataSource()
        appendContactsToDataSource()
        appendPhotosToDataSource()
        appendMailsToDataSource()
        collectionView.reloadData()
        
        note?.managedObjectContext?.perform { [weak self] in
            guard let `self` = self else { return }
            self.note?.deleteLosedIdentifiers(eventStore: self.eventStore, contactStore: self.contactStore)
            self.note?.managedObjectContext?.saveIfNeeded()
            
            self.detailVC?.mainContext.performAndWait {
                self.detailVC?.mainContext.saveIfNeeded()
            }
        }
    }

    private func setRecommend() {


    }

    private func appendRemindersToDataSource() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            eventStore.requestAccess(to: .reminder) { [weak self] (status, error) in
                switch status {
                case true: self?.fetchReminders()
                case false: self?.alertReminder()
                }
            }

        case .authorized: fetchReminders()
        case .restricted, .denied: alertReminder()
        }
    }

    private func appendEventsToDataSource() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            eventStore.requestAccess(to: .event) { [weak self] (status, error) in
                switch status {
                case true : self?.fetchEvents()
                case false: self?.alertEvent()
                }
            }
        case .authorized: fetchEvents()
        case .restricted, .denied: alertEvent()
        }
    }

    private func appendContactsToDataSource() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { [weak self] (status, error) in
                switch status {
                case true: self?.fetchContacts()
                case false: self?.alertContact()
                }
            }
        case .authorized: fetchContacts()
        case .restricted, .denied: alertContact()
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
                    self?.alertPhoto()
                }
            }
        case .authorized: fetchPhotos()
        default: alertPhoto()
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
                let reminderViewModel = ReminderViewModel(reminder: ekReminder, infoAction: nil, sectionTitle: "Reminder".loc, sectionImage: #imageLiteral(resourceName: "suggestionsReminder"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
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
                let eventViewModel = EventViewModel(event: ekEvent, infoAction: nil, sectionTitle: "Event".loc, sectionImage: #imageLiteral(resourceName: "suggestionsCalendar"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
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
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactViewController.descriptorForRequiredKeys()
        ]

        contactCollection.forEach { (value) in
            guard let contact = value as? Contact,
                let identifier = contact.identifier else { return }

            do {
                let cnContact = try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
                let contactViewModel = ContactViewModel(contact: cnContact, infoAction: nil, sectionTitle: "Contact".loc, sectionImage: #imageLiteral(resourceName: "suggestionsContact"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier, contactStore: contactStore)
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
            let minimumSize = CGSize(width: minLength / 3, height: minLength / 3)
            let photoViewModel = PhotoViewModel(asset: asset, infoAction: nil, imageManager: imageManager, minimumSize: minimumSize, sectionTitle: "Photos".loc, sectionImage: #imageLiteral(resourceName: "suggestionsPhotos"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
            photoViewModels.append(photoViewModel)
        }


        dataSource.append(photoViewModels)
    }

    private func fetchMails() {
        guard let mailCollection = note?.mailCollection else { return }
        var mailViewModels: [MailViewModel] = []

        mailCollection.forEach { (value) in
            guard let mail = value as? Mail else { return }
            let mailViewModel = MailViewModel(identifier: mail.identifier, infoAction: nil, sectionTitle: "Mail".loc, sectionImage: #imageLiteral(resourceName: "suggestionsMail"), sectionIdentifier: DetailCollectionReusableView.reuseIdentifier)
            mailViewModels.append(mailViewModel)
        }

        dataSource.append(mailViewModels)
    }
    
    private func alertLocation() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_location".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.detailVC?.present(alert, animated: true)
        }
    }
    
    private func alertReminder() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.detailVC?.present(alert, animated: true)
        }
        
    }
    
    private func alertEvent() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_event".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.detailVC?.present(alert, animated: true)
        }
    }
    
    private func alertPhoto() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_photo".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.detailVC?.present(alert, animated: true)
        }
    }
    
    private func alertContact() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_contact".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.detailVC?.present(alert, animated: true)
        }
    }
    
    func requestLocationAccess() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            alertLocation()
            break
            
        case .authorizedWhenInUse:
            break
            
        case .authorizedAlways:
            break
        }
    }
}

extension DetailInputView: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            // Disable your app's location features
            alertLocation()
            break
            
        case .authorizedWhenInUse:
            break
            
        case .authorizedAlways:
            break
            
        case .notDetermined:
            requestLocationAccess()
            break
        }
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

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? DetailCollectionReusableView.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = dataSource[indexPath.section][indexPath.item]
        return reusableView
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource[section].first?.headerSize ?? CGSize.zero
    }
}

extension DetailInputView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let detailVC = detailVC else { return }
        
        //메일의 경우 통신에 의해 데이터 소스가 바뀌며 셀 내부에 저장된다. 따라서 셀 내부에 있는 걸 불러와야한다.
        if let html = ((collectionView.cellForItem(at: indexPath) as? MailViewModelCell)?.data as? MailViewModel)?.message?.payload?.html { 
            guard let json = ((collectionView.cellForItem(at: indexPath) as? MailViewModelCell)?.data as? MailViewModel)?.message?.payload?.json else { return }

            detailVC.performSegue(withIdentifier: MailDetailViewController.identifier, sender: html)
        } else {
            dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: detailVC)
        }
        
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        
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
