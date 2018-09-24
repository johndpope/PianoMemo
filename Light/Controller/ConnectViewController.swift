//
//  ConnectViewController.swift
//  Piano
//
//  Created by Kevin Kim on 15/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit
import Contacts
import Photos

class ConnectViewController: UIViewController, CollectionRegisterable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    internal var notRegisteredData: MainViewController.NotRegisteredData!
    
    private var eventStore: EKEventStore!
    private let contactStore = CNContactStore()
    private var dataSource: [[CollectionDatable]] = []
    private var note: Note!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.eventStore = notRegisteredData.eventStore
        self.note = notRegisteredData.note
        
        registerHeaderView(PianoReusableView.self)
        registerCell(EKReminderCell.self)
        registerCell(EKEventCell.self)
        registerCell(CNContactCell.self)
        registerCell(PHAssetCell.self)
        
        collectionView.allowsMultipleSelection = true
        
        appendRemindersToDataSource()
        appendEventsToDataSource()
        appendContactsToDataSource()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        dataSource.enumerated().forEach { (section, datas) in
            datas.enumerated().forEach({ (item, _) in
                let indexPath = IndexPath(item: item, section: section)
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            })
        }
    }

}

extension ConnectViewController {
    @IBAction private func connect(_ sender: Any) {
        var hasAlert = false
        
        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
            indexPathsForSelectedItems.forEach { (indexPath) in
                let data = dataSource[indexPath.section][indexPath.item]
                
                if let ekReminder = data as? EKReminder {
                    do {
                        ekReminder.calendar = eventStore.defaultCalendarForNewReminders()
                        try eventStore.save(ekReminder, commit: false)
                    } catch {
                        print("ConnectViewController reminder connect 하다 에러: \(error.localizedDescription)")
                        hasAlert = true
                        Access.reminderRequest(from: self, success: nil)
                        return
                    }
                    
                    //catch를 안타고 성공했으면 코어데이터에 저장
                    guard let context = note.managedObjectContext else { return }
                    let reminder = Reminder(context: context)
                    reminder.createdDate = Date()
                    reminder.identifier = ekReminder.calendarItemExternalIdentifier
                    reminder.addToNoteCollection(note)
                    
                } else if let ekEvent = data as? EKEvent {
                    do {
                        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                        try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: false)
                    } catch {
                        print("ConnectViewController event connect 하다 에러: \(error.localizedDescription)")
                        hasAlert = true
                        Access.eventRequest(from: self, success: nil)
                        return
                    }
                    
                    //catch를 안타고 성공했으면 코어데이터에 저장
                    guard let context = note.managedObjectContext else { return }
                    let event = Event(context: context)
                    event.createdDate = Date()
                    event.identifier = ekEvent.calendarItemExternalIdentifier
                    event.addToNoteCollection(note)
                    
                } else if let cnContact = data as? CNContact {
                    guard let mutableContact = cnContact.mutableCopy() as? CNMutableContact else { return }
                    let request = CNSaveRequest()
                    request.add(mutableContact, toContainerWithIdentifier: nil)
                    do {
                        try contactStore.execute(request)
                    } catch {
                        print("ConnectViewController contact connect 하다 에러: \(error.localizedDescription)")
                        hasAlert = true
                        Access.contactRequest(from: self, success: nil)
                        return
                    }
                    
                    //catch를 안타고 성공했으면 코어데이터에 저장
                    guard let context = note.managedObjectContext else { return }
                    let contact = Contact(context: context)
                    contact.createdDate = Date()
                    contact.identifier = cnContact.identifier
                    contact.addToNoteCollection(note)
                    
                }
            }
        }

        do {
            try eventStore.commit()
        } catch {
            print("ConnectionViewController eventstore 커밋 과정에서 에러: \(error.localizedDescription)")
        }
        
        guard !hasAlert else { return }
        saveAndDismiss()
        
    }
    
    @IBAction private func skip(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private func saveAndDismiss() {
        note.managedObjectContext?.performAndWait {
            note.managedObjectContext?.saveIfNeeded()
            dismiss(animated: true, completion: nil)
        }
    }
    
}

extension ConnectViewController {
    private func appendRemindersToDataSource() {
        if notRegisteredData.remindersNotRegistered.count != 0 {
            dataSource.append(notRegisteredData.remindersNotRegistered)
        }
    }
    
    private func appendEventsToDataSource() {
        if notRegisteredData.eventsNotRegistered.count != 0 {
            let events = notRegisteredData.eventsNotRegistered
            dataSource.append(events)
        }
    }
    
    private func appendContactsToDataSource() {
        let contacts = notRegisteredData.contactsNotRegistered
        if contacts.count != 0 {
            dataSource.append(contacts)
        }
    }
}

extension ConnectViewController: UICollectionViewDataSource {
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
        cell.data = data
        return cell
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = dataSource[indexPath.section][indexPath.item]
        return reusableView
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource[section].first?.headerSize ?? CGSize.zero
    }
}

extension ConnectViewController: UICollectionViewDelegateFlowLayout {
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return dataSource[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
