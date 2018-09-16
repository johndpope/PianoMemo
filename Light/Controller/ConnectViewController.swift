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
        
        registerHeaderView(PianoCollectionReusableView.self)
        registerCell(ReminderViewModelCell.self)
        registerCell(EventViewModelCell.self)
        registerCell(ContactViewModelCell.self)
        registerCell(PhotoViewModelCell.self)
        registerCell(MailViewModelCell.self)
        
        collectionView.allowsMultipleSelection = true
        
        appendRemindersToDataSource()
        appendEventsToDataSource()
        appendContactsToDataSource()

    }

}

extension ConnectViewController {
    @IBAction private func connect(_ sender: Any) {
        var hasAlert = false
        
        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
            indexPathsForSelectedItems.forEach { (indexPath) in
                let data = dataSource[indexPath.section][indexPath.item]
                
                if let reminderViewModel = data as? ReminderViewModel {
                    do {
                        reminderViewModel.reminder.calendar = eventStore.defaultCalendarForNewReminders()
                        try eventStore.save(reminderViewModel.reminder, commit: false)
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
                    reminder.identifier = reminderViewModel.reminder.calendarItemExternalIdentifier
                    reminder.addToNoteCollection(note)
                    
                } else if let eventViewModel = data as? EventViewModel {
                    do {
                        eventViewModel.event.calendar = eventStore.defaultCalendarForNewEvents
                        try eventStore.save(eventViewModel.event, span: EKSpan.thisEvent, commit: false)
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
                    event.identifier = eventViewModel.event.calendarItemExternalIdentifier
                    event.addToNoteCollection(note)
                    
                } else if let contactViewModel = data as? ContactViewModel {
                    guard let mutableContact = contactViewModel.contact.mutableCopy() as? CNMutableContact else { return }
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
                    contact.identifier = contactViewModel.contact.identifier
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
        note.managedObjectContext?.saveIfNeeded()
        dismiss(animated: true, completion: nil)
    }
    
}

extension ConnectViewController {
    private func appendRemindersToDataSource() {
        if notRegisteredData.remindersNotRegistered.count != 0 {
            let reminders = notRegisteredData.remindersNotRegistered.map { ReminderViewModel(reminder: $0, sectionTitle: "Reminder".loc, sectionImage: #imageLiteral(resourceName: "suggestionsReminder"), sectionIdentifier: PianoCollectionReusableView.reuseIdentifier)}
            dataSource.append(reminders)
        }
    }
    
    private func appendEventsToDataSource() {
        if notRegisteredData.eventsNotRegistered.count != 0 {
            let events = notRegisteredData.eventsNotRegistered.map { EventViewModel(event: $0, sectionTitle: "Event".loc, sectionImage: #imageLiteral(resourceName: "suggestionsCalendar"), sectionIdentifier: PianoCollectionReusableView.reuseIdentifier)}
            dataSource.append(events)
        }
    }
    
    private func appendContactsToDataSource() {
        if notRegisteredData.contactsNotRegistered.count != 0 {
            let contacts = notRegisteredData.contactsNotRegistered.map { ContactViewModel(contact: $0, sectionTitle: "Contact".loc, sectionImage: #imageLiteral(resourceName: "suggestionsContact"), sectionIdentifier: PianoCollectionReusableView.reuseIdentifier, contactStore: contactStore)}
            dataSource.append(contacts)
        }
    }
}

extension ConnectViewController: UICollectionViewDataSource {
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.identifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
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
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? PianoCollectionReusableView.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = dataSource[indexPath.section][indexPath.item]
        return reusableView
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource[section].first?.headerSize ?? CGSize.zero
    }
}

extension ConnectViewController: UICollectionViewDelegate {
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
        
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
    }
}

extension ConnectViewController: UICollectionViewDelegateFlowLayout {
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset ?? UIEdgeInsets.zero
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maximumWidth = collectionView.bounds.width - (collectionView.marginLeft + collectionView.marginRight)
        return dataSource[indexPath.section][indexPath.item].size(maximumWidth: maximumWidth)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
