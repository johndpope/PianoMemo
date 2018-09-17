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
import Photos

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
    internal func deleteLosedIdentifiers(eventStore: EKEventStore, contactStore: CNContactStore) {
        deleteLosedReminderIdentifiers(eventStore: eventStore)
        deleteLosedEventIdentifiers(eventStore: eventStore)
        deleteLosedContactIdentifiers(contactStore: contactStore)
        deleteLosedPhotoIdentifiers()
        deleteLosedMailIdentifiers()
    }
    
    private func deleteLosedPhotoIdentifiers() {
        
    }
    
    private func deleteLosedMailIdentifiers() {
        
    }
    
    internal var remindersRegistered: [EKReminder] {
        let store = EKEventStore()
        return reminderIdentifiers.compactMap { store.calendarItems(withExternalIdentifier: $0).first as? EKReminder }
    }
    
    internal var eventsRegistered: [EKEvent] {
        let store = EKEventStore()
        return eventIdentifiers.compactMap { store.calendarItems(withExternalIdentifier: $0).first as? EKEvent }
    }
    
    internal var contactsRegistered: [CNContact] {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]
        return contactIdentifiers.compactMap { try? store.unifiedContact(withIdentifier: $0, keysToFetch: keys)}
    }
    
    internal var photosRegistered: [PHAsset] {
        let results = PHAsset.fetchAssets(withLocalIdentifiers: photoIdentifiers, options: nil)
        
        var assets : [PHAsset] = []
        results.enumerateObjects { (asset, offset, _) in
            assets.append(asset)
        }
        return assets
    }
    
    internal var mailRegistered: [String] {
        return mailIdentifiers
    }
    
    internal func remindersNotRegistered(store: EKEventStore) -> [EKReminder] {
        guard let paraStrings = content?.split(separator: "\n") else { return [] }
        
        //이미 등록되어있는 리마인더와 비교하고 같지 않다면 리턴
        let noteReminders = remindersRegistered
        
        return paraStrings.compactMap { String($0).reminder(store: store)}.filter({ (reminder) -> Bool in
            !noteReminders.contains(where: { (noteReminder) -> Bool in
                noteReminder.title == reminder.title && noteReminder.alarmDate == reminder.alarmDate
            })
        })
    }
    
    internal func eventsNotRegistered(store: EKEventStore) -> [EKEvent] {
        guard let paraStrings = content?.split(separator: "\n") else { return [] }
        
        let noteEvents = eventsRegistered
        return paraStrings.compactMap { String($0).event(store: store)}.filter({ (event) -> Bool in
            !noteEvents.contains(where: { (noteEvent) -> Bool in
                noteEvent.title == event.title && noteEvent.startDate == event.startDate && noteEvent.endDate == event.endDate
            })
        })
    }
    
    internal func contactsNotRegistered() -> [CNContact] {
        guard let paraStrings = content?.split(separator: "\n") else { return [] }
        
        let noteContacts = contactsRegistered
        return paraStrings.compactMap { String($0).contact()}.filter({ (contact) -> Bool in
            !noteContacts.contains(where: { (noteContact) -> Bool in
                noteContact.givenName == contact.givenName && noteContact.familyName == contact.familyName
            })
        })
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
        }
    }
}


extension Note {
    var reminderIdentifiers: [String] {
        return reminderCollection?.compactMap({ (value) -> String? in
            guard let reminder = value as? Reminder else { return nil }
            return reminder.identifier
        }) ?? []
    }
    
    var eventIdentifiers: [String] {
        return eventCollection?.compactMap({ (value) -> String? in
            guard let event = value as? Event else { return nil }
            return event.identifier
        }) ?? []
    }
    
    var contactIdentifiers: [String] {
        return contactCollection?.compactMap({ (value) -> String? in
            guard let contact = value as? Contact else { return nil }
            return contact.identifier
        }) ?? []
    }
    
    var photoIdentifiers: [String] {
        return photoCollection?.compactMap({ (value) -> String? in
            guard let photo = value as? Photo else { return nil }
            return photo.identifier
        }) ?? []
    }
    
    var mailIdentifiers: [String] {
        return mailCollection?.compactMap({ (value) -> String? in
            guard let mail = value as? Mail else { return nil }
            return mail.identifier
        }) ?? []
    }
    
}
