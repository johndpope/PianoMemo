////
////  LinkCollectionViewController.swift
////  Piano
////
////  Created by Kevin Kim on 24/09/2018.
////  Copyright © 2018 Piano. All rights reserved.
////
//
//import UIKit
//import EventKit
//import ContactsUI
//import Photos
//
//class LinkCollectionViewController: UICollectionViewController, CollectionRegisterable, NoteEditable {
//
//    @IBOutlet weak var addButton: BarButtonItem!
//    
//    //RxSwift의 기능을 써야함.
//    var trigger: Int = 0 {
//        didSet {
//            print(trigger)
//            if trigger == 4 {
//                DispatchQueue.main.async { [weak self] in
//                    guard let `self` = self else { return }
//                    self.collectionView.reloadData()
//                    self.resetTrigger()
//                }
//            }
//        }
//    }
//    //TODO: refactor 대상
//    var needsUpdate = false
//    
//    private func increaseTrigger(){ trigger += 1 }
//    private func resetTrigger() { trigger = 0 }
//    
//    var dataSource: [[CollectionDatable]] = []
//    var note: Note!
//    
//    private lazy var eventStore = EKEventStore()
//    private lazy var contactStore = CNContactStore()
//    private lazy var imageManager = PHCachingImageManager()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        registerHeaderView(PianoReusableView.self)
//        registerCell(EKReminderCell.self)
//        registerCell(EKEventCell.self)
//        registerCell(CNContactCell.self)
//        registerCell(PHAssetCell.self)
//        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
//        clearsSelectionOnViewWillAppear = true
//        appendAllDatasToDatasources()
//    }
//    
//    private func appendAllDatasToDatasources() {
//        DispatchQueue.global().async { [weak self] in
//            guard let `self` = self else { return }
//            self.resetTrigger()
//            self.dataSource = []
//            self.appendRemindersToDataSource()
//            self.appendEventsToDataSource()
//            self.appendContactsToDataSource()
//            self.appendPhotosToDataSource()
//        }
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//    }
//    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        coordinator.animate(alongsideTransition: nil) { [weak self](context) in
//            guard let `self` = self,
//                let collectionView = self.collectionView else { return }
//            collectionView.collectionViewLayout.invalidateLayout()
//        }
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        if needsUpdate {
//            appendAllDatasToDatasources()
//            needsUpdate = false
//        }
//    }
//    
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        if let navVC = segue.destination as? UINavigationController,
//            let vc = navVC.topViewController as? NoteEditable {
//            vc.note = note
//            return
//        }
//        
//        if let navVC = segue.destination as? UINavigationController,
//            let vc = navVC.topViewController as? PhotoDetailViewController,
//            let asset = sender as? PHAsset {
//            vc.asset = asset
//            return
//        }
//        
//        if let vc = segue.destination as? PhotoDetailViewController,
//            let asset = sender as? PHAsset {
//            vc.asset = asset
//            return
//        }
//        
//        if let vc = segue.destination as? EventDetailViewController,
//            let ekEvent = sender as? EKEvent {
//            vc.event = ekEvent
//            vc.allowsEditing = true
//            return
//        }
//        
//    }
//
//}
//
//extension LinkCollectionViewController {
//    private func presentActionSheet(sender: UIBarButtonItem) {
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        
//        let reminder =  UIAlertAction(title: "미리알림", style: .default) { [weak self] (_) in
//            guard let `self` = self else { return }
//            self.performSegue(withIdentifier: ReminderPickerCollectionViewController.identifier, sender: nil)
//        }
//        
//        let event = UIAlertAction(title: "캘린더", style: .default) { [weak self] (_) in
//            guard let `self` = self else { return }
//            self.performSegue(withIdentifier: EventPickerCollectionViewController.identifier, sender: nil)
//        }
//        
//        let contact = UIAlertAction(title: "연락처", style: .default) { [weak self] (_) in
//            guard let `self` = self else { return }
//            self.performSegue(withIdentifier: ContactPickerCollectionViewController.identifier, sender: nil)
//        }
//        
//        let photo = UIAlertAction(title: "사진", style: .default) { [weak self] (_) in
//            guard let `self` = self else { return }
//            self.performSegue(withIdentifier: PhotoPickerCollectionViewController.identifier, sender: nil)
//        }
//        
//        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//        
//        alertController.addAction(reminder)
//        alertController.addAction(event)
//        alertController.addAction(contact)
//        alertController.addAction(photo)
//        alertController.addAction(cancel)
//        if let controller = alertController.popoverPresentationController {
//            controller.barButtonItem = sender
//        }
//        
//        
//        present(alertController, animated: true, completion: nil)
//    }
//}
//
//extension LinkCollectionViewController {
//    
//    @IBAction func add(_ sender: UIBarButtonItem) {
//        presentActionSheet(sender: sender)
//        needsUpdate = true
//    }
//}
//
//extension LinkCollectionViewController {
//    
//    private func appendRemindersToDataSource() {
//        guard let reminderCollection = note?.reminderCollection,
//            reminderCollection.count != 0  else {
//                increaseTrigger()
//                return
//        }
//        
//        Access.reminderRequest(from: self) { [weak self] in
//            guard let `self` = self else { return }
//            var ekReminders: [EKReminder] = []
//            
//            reminderCollection.forEach { (value) in
//                guard let reminder = value as? Reminder,
//                    let identifier = reminder.identifier else { return }
//                if let ekReminder = self.eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKReminder {
//                    if Date() < (ekReminder.alarmDate ?? Date()) {
//                        ekReminders.append(ekReminder)
//                    }
//                }
//            }
//            self.dataSource.append(ekReminders)
//            self.increaseTrigger()
//        }
//    }
//    
//    private func appendEventsToDataSource() {
//        guard let eventCollection = note?.eventCollection,
//            eventCollection.count != 0 else {
//                increaseTrigger()
//                return
//        }
//        
//        Access.eventRequest(from: self) { [weak self] in
//            guard let `self` = self else { return }
//            var ekEvents: [EKEvent] = []
//            eventCollection.forEach { (value) in
//                guard let event = value as? Event,
//                    let identifier = event.identifier,
//                    let ekEvent = self.eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKEvent else { return }
//                //오늘 날짜보다 이후인 것만 보여준다.
//                if Date() < ekEvent.endDate {
//                    ekEvents.append(ekEvent)
//                }
//            }
//            self.dataSource.append(ekEvents)
//            self.increaseTrigger()
//        }
//    }
//    
//    private func appendContactsToDataSource() {
//        guard let contactCollection = note?.contactCollection,
//            contactCollection.count != 0 else {
//                increaseTrigger()
//                return
//        }
//        
//        Access.contactRequest(from: self) { [weak self] in
//            guard let `self` = self else { return }
//            var cnContacts: [CNContact] = []
//            
//            let keys: [CNKeyDescriptor] = [
//                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
//                CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName),
//                CNContactPhoneNumbersKey as CNKeyDescriptor,
//                CNContactEmailAddressesKey as CNKeyDescriptor,
//                CNContactViewController.descriptorForRequiredKeys()
//            ]
//            
//            contactCollection.forEach { (value) in
//                guard let contact = value as? Contact,
//                    let identifier = contact.identifier else { return }
//                
//                do {
//                    let cnContact = try self.contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
//                    cnContacts.append(cnContact)
//                    return
//                } catch {
//                    print("in: fetchContacts 연락처가 가져와지지 않아요. : \(error.localizedDescription) ")
//                }
//            }
//            
//            self.dataSource.append(cnContacts)
//            self.increaseTrigger()
//        }
//    }
//    
//    private func appendPhotosToDataSource() {
//        guard let photoCollection = note?.photoCollection, photoCollection.count != 0 else {
//            increaseTrigger()
//            return
//        }
//        
//        Access.photoRequest(from: self) { [weak self] in
//            guard let `self` = self else { return }
//            var pHAssets: [PHAsset] = []
//            let identifiers = photoCollection.compactMap { (value) -> String? in
//                guard let photo = value as? Photo,
//                    let identifier = photo.identifier else {return nil }
//                return identifier
//            }
//            
//            let results = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
//            guard results.count != 0 else { return }
//            for i in 0 ... results.count - 1 {
//                let pHAsset = results.object(at: i)
//                pHAssets.append(pHAsset)
//            }
//            
//            self.dataSource.append(pHAssets)
//            self.increaseTrigger()
//        }
//    }
//}
//
//extension LinkCollectionViewController {
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        
//        let data = dataSource[indexPath.section][indexPath.item]
//        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! UICollectionViewCell & CollectionDataAcceptable
//        if cell is PHAssetCell {
//            (cell as! PHAssetCell).imageManager = imageManager
//            (cell as! PHAssetCell).collectionView = collectionView
//        }
//        
//        cell.data = data
//        return cell
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return dataSource[section].count
//    }
//    
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return dataSource.count
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
//        reusableView.data = dataSource[indexPath.section][indexPath.item]
//        return reusableView
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return dataSource[section].first?.headerSize ?? CGSize.zero
//    }
//}
//
//extension LinkCollectionViewController {
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: self)
//        needsUpdate = true
//        collectionView.deselectItem(at: indexPath, animated: true)
//    }
//}
//
//extension LinkCollectionViewController: UICollectionViewDelegateFlowLayout {
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return dataSource[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return dataSource[indexPath.section][indexPath.item].size(view: collectionView)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return dataSource[section].first?.minimumLineSpacing ?? 0
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return dataSource[section].first?.minimumInteritemSpacing ?? 0
//    }
//    
//}
