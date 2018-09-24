//
//  LinkCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 24/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit
import ContactsUI
import Photos

class LinkCollectionViewController: UICollectionViewController, CollectionRegisterable, NoteEditable {

    @IBOutlet weak var addButton: BarButtonItem!
    var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.collectionView.reloadData()
            }
        }
    }
    var note: Note!
    
    private lazy var eventStore = EKEventStore()
    private lazy var contactStore = CNContactStore()
    private lazy var imageManager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerHeaderView(PianoReusableView.self)
        registerCell(EKReminderCell.self)
        registerCell(EKEventCell.self)
        registerCell(CNContactCell.self)
        registerCell(PHAssetCell.self)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        clearsSelectionOnViewWillAppear = true
    }
    
    //TODO: Code Refactoring
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerRotationNotification()
        appendAllDatasToDatasources()
    }
    
    private func appendAllDatasToDatasources() {
        dataSource = []
        appendRemindersToDataSource()
        appendEventsToDataSource()
        appendContactsToDataSource()
        appendPhotosToDataSource()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterRotationNotification()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.topViewController as? NoteEditable {
            vc.note = note
            return
        }
        
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.topViewController as? PhotoDetailViewController,
            let asset = sender as? PHAsset {
            vc.asset = asset
            return
        }
        
        if let vc = segue.destination as? PhotoDetailViewController,
            let asset = sender as? PHAsset {
            vc.asset = asset
            return
        }
        
        if let vc = segue.destination as? EventDetailViewController,
            let ekEvent = sender as? EKEvent {
            vc.event = ekEvent
            vc.allowsEditing = true
            return
        }
        
    }

}

extension LinkCollectionViewController {
    private func presentActionSheet(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let reminder =  UIAlertAction(title: "미리알림", style: .default) { [weak self] (_) in
            guard let `self` = self else { return }
            self.performSegue(withIdentifier: ReminderPickerCollectionViewController.identifier, sender: nil)
        }
        
        let event = UIAlertAction(title: "캘린더", style: .default) { [weak self] (_) in
            guard let `self` = self else { return }
            self.performSegue(withIdentifier: EventPickerCollectionViewController.identifier, sender: nil)
        }
        
        let contact = UIAlertAction(title: "연락처", style: .default) { [weak self] (_) in
            guard let `self` = self else { return }
            self.performSegue(withIdentifier: ContactPickerCollectionViewController.identifier, sender: nil)
        }
        
        let photo = UIAlertAction(title: "사진", style: .default) { [weak self] (_) in
            guard let `self` = self else { return }
            self.performSegue(withIdentifier: PhotoPickerCollectionViewController.identifier, sender: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(reminder)
        alertController.addAction(event)
        alertController.addAction(contact)
        alertController.addAction(photo)
        alertController.addAction(cancel)
        if let controller = alertController.popoverPresentationController {
            controller.barButtonItem = sender
        }
        
        
        present(alertController, animated: true, completion: nil)
    }
}

extension LinkCollectionViewController {
    //TODO: 레이아웃만 invalidate 하여 해결 하는 법 찾기(현재는 다시 reload하여 임시방편으로 해결)
    @objc private func invalidLayout() {
        appendAllDatasToDatasources()
    }
    
    private func registerRotationNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(invalidLayout), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    private func unRegisterRotationNotification() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        presentActionSheet(sender: sender)
    }
}

extension LinkCollectionViewController {
    
    private func appendRemindersToDataSource() {
        guard let reminderCollection = note?.reminderCollection,
            reminderCollection.count != 0  else { return }
        
        Access.reminderRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            var ekReminders: [EKReminder] = []
            reminderCollection.forEach { (value) in
                guard let reminder = value as? Reminder,
                    let identifier = reminder.identifier else { return }
                
                if let ekReminder = self.eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKReminder {
                    ekReminders.append(ekReminder)
                    return
                }
            }
            self.dataSource.append(ekReminders)
        }
    }
    
    private func appendEventsToDataSource() {
        guard let eventCollection = note?.eventCollection,
            eventCollection.count != 0 else { return }
        
        Access.eventRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            var ekEvents: [EKEvent] = []
            eventCollection.forEach { (value) in
                guard let event = value as? Event,
                    let identifier = event.identifier,
                    let ekEvent = self.eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKEvent else { return }
                ekEvents.append(ekEvent)
            }
            self.dataSource.append(ekEvents)
        }
    }
    
    private func appendContactsToDataSource() {
        guard let contactCollection = note?.contactCollection,
            contactCollection.count != 0 else { return }
        
        Access.contactRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            var cnContacts: [CNContact] = []
            
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
                    let cnContact = try self.contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
                    cnContacts.append(cnContact)
                    return
                } catch {
                    print("in: fetchContacts 연락처가 가져와지지 않아요. : \(error.localizedDescription) ")
                }
            }
            
            self.dataSource.append(cnContacts)
        }
    }
    
    private func appendPhotosToDataSource() {
        guard let photoCollection = note?.photoCollection, photoCollection.count != 0 else { return }
        
        Access.photoRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            var pHAssets: [PHAsset] = []
            let identifiers = photoCollection.compactMap { (value) -> String? in
                guard let photo = value as? Photo,
                    let identifier = photo.identifier else {return nil }
                return identifier
            }
            
            let results = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            guard results.count != 0 else { return }
            for i in 0 ... results.count - 1 {
                let pHAsset = results.object(at: i)
                pHAssets.append(pHAsset)
            }
            
            self.dataSource.append(pHAssets)
        }
    }
}

extension LinkCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! UICollectionViewCell & CollectionDataAcceptable
        if cell is PHAssetCell {
            (cell as! PHAssetCell).imageManager = imageManager
            (cell as! PHAssetCell).collectionView = collectionView
        }
        
        cell.data = data
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = dataSource[indexPath.section][indexPath.item]
        return reusableView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource[section].first?.headerSize ?? CGSize.zero
    }
}

extension LinkCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataSource[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: self)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension LinkCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return dataSource[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
