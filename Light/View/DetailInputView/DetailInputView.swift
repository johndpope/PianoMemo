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
    case linked
    case relevant
}

class DetailInputView: UIView, CollectionRegisterable {
    /**
     여기에 type만 세팅해주면 자동으로 바뀜
    */
    public var type: InputType? {
        didSet {
            reset()

            guard let type = self.type else { return }
            switch type {
            case .linked:
                setConnect()
            case .relevant:
                setRelevant()
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

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(reminder)
        alertController.addAction(event)
        alertController.addAction(contact)
        alertController.addAction(photo)
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
        
        registerHeaderView(PianoReusableView.self)
        registerCell(EKReminderCell.self)
        registerCell(EKEventCell.self)
        registerCell(CNContactCell.self)
        registerCell(PHAssetCell.self)
        

        appendRemindersToDataSource()
        appendEventsToDataSource()
        appendContactsToDataSource()
        appendPhotosToDataSource()
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        collectionView.reloadData()
        
    }

    private func setRelevant() {
        registerHeaderView(PianoReusableView.self)
        registerCell(EKReminderCell.self)
        registerCell(EKEventCell.self)
        registerCell(CNContactCell.self)
        registerCell(PHAssetCell.self)

    }

    private func appendRemindersToDataSource() {
        guard let reminderCollection = note?.reminderCollection else { return }
        var ekReminders: [EKReminder] = []
        
        reminderCollection.forEach { (value) in
            guard let reminder = value as? Reminder,
                let identifier = reminder.identifier else { return }
            
            if let ekReminder = eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKReminder {
                ekReminders.append(ekReminder)
                return
            }
        }
        
        dataSource.append(ekReminders)
    }

    private func appendEventsToDataSource() {
        guard let eventCollection = note?.eventCollection else { return }
        var ekEvents: [EKEvent] = []
        
        eventCollection.forEach { (value) in
            guard let event = value as? Event,
                let identifier = event.identifier,
                let ekEvent = eventStore.calendarItems(withExternalIdentifier: identifier).first as? EKEvent else { return }
            ekEvents.append(ekEvent)
        }
        
        dataSource.append(ekEvents)
    }

    private func appendContactsToDataSource() {
        guard let contactCollection = note?.contactCollection else { return }
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
                let cnContact = try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
                cnContacts.append(cnContact)
                return
            } catch {
                print("in: fetchContacts 연락처가 가져와지지 않아요. : \(error.localizedDescription) ")
            }
        }
        dataSource.append(cnContacts)
    }

    private func appendPhotosToDataSource() {
        guard let photoCollection = note?.photoCollection else { return }
        let identifiers = photoCollection.compactMap { (value) -> String? in
            guard let photo = value as? Photo,
                let identifier = photo.identifier else {return nil }
            return identifier
        }
        
        //이걸 하지 않으면 엑세스 허용을 묻게됨
        guard identifiers.count != 0 else { return }
        
        let results = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var pHAssets: [PHAsset] = []
        guard results.count != 0 else { return }
        for i in 0 ... results.count - 1 {
            let pHAsset = results.object(at: i)
            pHAssets.append(pHAsset)
        }
        
        dataSource.append(pHAssets)
 
    }
}

extension DetailInputView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! UICollectionViewCell & CollectionDataAcceptable
        if cell is PHAssetCell {
            (cell as! PHAssetCell).imageManager = imageManager
            (cell as! PHAssetCell).collectionView = collectionView
        }
        
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
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
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
        dataSource[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: detailVC)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension DetailInputView: UICollectionViewDelegateFlowLayout {

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
