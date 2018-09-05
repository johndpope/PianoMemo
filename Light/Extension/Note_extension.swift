//
//  Note_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import ContactsUI

struct NoteAttributes: Codable {
    let highlightRanges: [NSRange]
}


extension Note {
    var atttributes: NoteAttributes? {
        get {
            guard let attributeData = attributeData else { return nil }
            return try? JSONDecoder().decode(NoteAttributes.self, from: attributeData)
        } set {
            let data = try? JSONEncoder().encode(newValue)
            attributeData = data
        }
    }
}

extension Note {
    
    internal func connectData() {
        guard let paraStrings = content?.components(separatedBy: .newlines) else { return }
        
        let eventStore = EKEventStore()
        let contactStore = CNContactStore()
        
        deleteLosedReminderIdentifiers(eventStore: eventStore)
        deleteLosedEventIdentifiers(eventStore: eventStore)
        deleteLosedContactIdentifiers(contactStore: contactStore)
        
        var remindersToAdd: [EKReminder] = []
        var remindersToDelete: [EKReminder : Reminder] = [:]
        
        var eventsToAdd: [EKEvent] = []
        var eventsToDelete: [EKEvent : Event] = [:]
        
        var contactsToAdd: [CNContact] = []
        var contactsToDelete: [CNContact : Contact] = [:]
        
        paraStrings.forEach {
            if let reminderDetected = $0.reminder() {
                let deleteDic = self.remindersToDelete(reminderDetected: reminderDetected, store: eventStore)
                deleteDic.forEach({ (ekReminder, reminder) in
                    remindersToDelete[ekReminder] = reminder
                })
                let ekReminder = reminderDetected.createEKReminder(store: eventStore)
                remindersToAdd.append(ekReminder)
                
            } else if let eventDetected = $0.event() {
                let deleteDic = self.eventsToDelete(eventDetected: eventDetected, store: eventStore)
                deleteDic.forEach({ (ekEvent, event) in
                    eventsToDelete[ekEvent] = event
                })
                let ekEvent = eventDetected.createEKEvent(store: eventStore)
                eventsToAdd.append(ekEvent)
                
            } else if let contactDetected = $0.contact() {
                let deleteDic = self.contactsToDelete(contactDetected: contactDetected, store: contactStore)
                deleteDic.forEach({ (cnContact, contact) in
                    contactsToDelete[cnContact] = contact
                })
                let cnContact = contactDetected.createCNContact()
                contactsToAdd.append(cnContact)
            }
        }
        
        delete(reminderDic: remindersToDelete, store: eventStore)
        add(reminders: remindersToAdd, store: eventStore)
        
        delete(eventDic: eventsToDelete, store: eventStore)
        add(events: eventsToAdd, store: eventStore)
        
        delete(contactDic: contactsToDelete, store: contactStore)
        add(contact: contactsToAdd, store: contactStore)
        
        do {
            saveIfNeeded()
            try eventStore.commit()
        } catch {
            print("reminder eventStore commit error: \(error.localizedDescription)")
        }
    }
}

extension Note {
    enum ConnectType {
        case reminder
        case calendar
        case contact
        case phoneNum
        case address
        case mail
    }
    
    private var cnContactFetchKeys: [CNKeyDescriptor] {
        return [CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor]
    }
    
    /**
     리마인더 앱에서 삭제한 리마인더들의 identifier들은 더이상 의미가 없으므로 삭제시킨다.
     */
    private func deleteLosedReminderIdentifiers(eventStore: EKEventStore) {
        guard let context = managedObjectContext else { return }
        
        var noteRemindersToDelete: [Reminder] = []
        reminderCollection?.forEach {
            guard let noteReminder = $0 as? Reminder,
                let identifier = noteReminder.identifier,
                eventStore.calendarItems(withExternalIdentifier: identifier).count == 0 else { return }
            noteRemindersToDelete.append(noteReminder)
        }
        
        noteRemindersToDelete.forEach {
            context.delete($0)
        }
        //EKEvent를 저장/삭제한 게 아니므로 코어데이터만 삭제
        saveIfNeeded()
    }
    
    /**
     캘린더 앱에서 삭제한 event들의 identifier들은 더이상 의미가 없으므로 삭제시킨다.
     */
    private func deleteLosedEventIdentifiers(eventStore: EKEventStore) {
        guard let context = managedObjectContext else { return }
        
        //캘린더 앱에서 삭제한 캘린더들의 identifier들은 더이상 의미가 없으므로 삭제시킨다.
        var noteEventsToDelete: [Event] = []
        eventCollection?.forEach {
            guard let noteEvent = $0 as? Event,
                let identifier = noteEvent.identifier,
                eventStore.calendarItems(withExternalIdentifier: identifier).count == 0 else { return }
            noteEventsToDelete.append(noteEvent)
        }
        
        noteEventsToDelete.forEach {
            context.delete($0)
        }
        saveIfNeeded()
    }
    
    /**
     연락처 앱에서 삭제한 event들의 identifier들은 더이상 의미가 없으므로 삭제시킨다.
     */
    private func deleteLosedContactIdentifiers(contactStore: CNContactStore) {
        guard let context = managedObjectContext else { return }
        
        var noteContactsToDelete: [Contact] = []
        let CNContactFetchKeys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor,
                                                     CNContactFamilyNameKey as CNKeyDescriptor,
                                                     CNContactPhoneNumbersKey as CNKeyDescriptor,
                                                     CNContactEmailAddressesKey as CNKeyDescriptor]
        
        contactCollection?.forEach {
            guard let noteContact = $0 as? Contact,
                let identifier = noteContact.identifier else { return }
            
            do {
                let _ = try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: CNContactFetchKeys)
            } catch {
                print("아이덴티파이어가 없으니 지우겠습니당.")
                noteContactsToDelete.append(noteContact)
            }
            
            noteContactsToDelete.forEach {
                context.delete($0)
            }
            
            saveIfNeeded()
        }
    }
    
    private func remindersToDelete(reminderDetected: String.Reminder, store: EKEventStore) -> [EKReminder : Reminder] {
        guard let reminderCollection = reminderCollection else { return [:] }
        var remindersToDelete: [EKReminder : Reminder] = [:]
        
        for value in reminderCollection {
            guard let noteReminder = value as? Reminder,
                let identifier = noteReminder.identifier,
                let existReminder = store.calendarItems(withExternalIdentifier: identifier).filter({ (item) -> Bool in
                    item.title.trimmingCharacters(in: .whitespaces) == reminderDetected.title.trimmingCharacters(in: .whitespaces)
                }).first as? EKReminder else { continue }
            
            
            remindersToDelete[existReminder] = noteReminder
            break
        }
        
        return remindersToDelete
    }
    
    private func eventsToDelete(eventDetected: String.Event, store: EKEventStore) -> [EKEvent : Event] {
        guard let eventCollection = eventCollection else { return [:] }
        var eventsToDelete: [EKEvent : Event] = [:]
        
        for value in eventCollection {
            guard let noteEvent = value as? Event,
                let identifier = noteEvent.identifier,
                let existEvent = store.calendarItems(withExternalIdentifier: identifier).filter({ (item) -> Bool in
                    item.title.trimmingCharacters(in: .whitespaces) == eventDetected.title.trimmingCharacters(in: .whitespaces)
                }).first as? EKEvent
                else { continue }
            
            eventsToDelete[existEvent] = noteEvent
            break
        }
        
        return eventsToDelete
    }
    
    private func contactsToDelete(contactDetected: String.Contact, store: CNContactStore) -> [CNContact : Contact] {
        guard let contactCollection = contactCollection else { return [:] }
        var contactsToDelete: [CNContact : Contact] = [:]
        
        for value in contactCollection {
            guard let noteContact = value as? Contact,
                let identifier = noteContact.identifier,
                let existContact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: cnContactFetchKeys)
                else { continue }
            
            if let existNumStr = existContact.phoneNumbers.first?.value.stringValue,
                let detectNumStr = contactDetected.phones.first,
                existNumStr == detectNumStr {
                contactsToDelete[existContact] = noteContact
                break
                
            } else if let existMailStr = existContact.emailAddresses.first?.value as String?,
                let detectMailStr = contactDetected.mails.first,
                existMailStr == detectMailStr {
                contactsToDelete[existContact] = noteContact
                break
            }
        }
        
        return contactsToDelete
    }
    
    private func delete(reminderDic: [EKReminder : Reminder], store: EKEventStore) {
        guard let context = managedObjectContext else { return }
        
        reminderDic.forEach { (ekReminder, noteReminder) in
            context.delete(noteReminder)
            do {
                try store.remove(ekReminder, commit: false)
            } catch {
                print("지워야할 리마인더 루프 돌다 에러: \(error.localizedDescription)")
            }
        }
    }
    
    private func add(reminders: [EKReminder], store: EKEventStore) {
        guard let context = managedObjectContext else { return }
        
        reminders.forEach { (ekReminder) in
            let noteReminder = Reminder(context: context)
            noteReminder.identifier = ekReminder.calendarItemExternalIdentifier
            noteReminder.addToNoteCollection(self)
            do {
                try store.save(ekReminder, commit: false)
            } catch {
                print("추가해야할 리마인더 루프 돌다 에러: \(error.localizedDescription)")
            }
        }
    }
    
    private func delete(eventDic: [EKEvent : Event], store: EKEventStore) {
        guard let context = managedObjectContext else { return }
        
        eventDic.forEach({ (ekEvent, noteEvent) in
            context.delete(noteEvent)
            do {
                try store.remove(ekEvent, span: EKSpan.thisEvent, commit: false)
            } catch {
                print("지워야할 이벤트 루프 돌다 에러: \(error.localizedDescription)")
            }
        })
    }
    
    private func add(events: [EKEvent], store: EKEventStore) {
        guard let context = managedObjectContext else { return }
        
        events.forEach{ (ekEvent) in
            let noteEvent = Event(context: context)
            noteEvent.identifier = ekEvent.calendarItemExternalIdentifier
            noteEvent.addToNoteCollection(self)
            do {
                try store.save(ekEvent, span: EKSpan.thisEvent, commit: false)
            } catch {
                print("추가해야할 리마인더: \(error.localizedDescription)")
            }
        }
    }
    
    private func delete(contactDic: [CNContact : Contact], store: CNContactStore) {
        guard let context = managedObjectContext else { return }
        
        contactDic.forEach({ (cnContact, noteContact) in
            guard let mutableCNContact = cnContact.mutableCopy() as? CNMutableContact else {
                print("연락처 mutable로 만드는 과정에서 에러")
                return
            }
            context.delete(noteContact)
            
            let request = CNSaveRequest()
            request.delete(mutableCNContact)
            do {
                try store.execute(request)
            } catch {
                print("연락처 mutable로 만들고 제거하는 과정에서 에러: \(error.localizedDescription)")
            }
        })
    }
    
    private func add(contact: [CNContact], store: CNContactStore) {
        guard let context = managedObjectContext else { return }
        
        contact.forEach({ (cnContact) in
            guard let mutableCNContact = cnContact.mutableCopy() as? CNMutableContact else {
                print("연락처 mutable로 만들고 더하는 과정에서 에러")
                return
            }
            let noteContact = Contact(context: context)
            noteContact.identifier = cnContact.identifier
            noteContact.addToNoteCollection(self)
            let request = CNSaveRequest()
            request.add(mutableCNContact, toContainerWithIdentifier: nil)
            do {
                try store.execute(request)
            } catch {
                print("contactStore request 실행하는 도중 에러")
            }
        })
    }
}
