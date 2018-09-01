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
    enum ConnectType {
        case reminder
        case calendar
        case contact
        case phoneNum
        case address
        case mail
    }
    
    func connectData() {
        guard let text = content else { return }
        do {
            let eventStore = EKEventStore()
            let contactStore = CNContactStore()
            let paraArray = text.components(separatedBy: .newlines)
            for paraString in paraArray {
                //아래의 순서로 진행하여야 함
                if let reminder = paraString.reminder() {
                    
                    //reminderCollection을 돌아서 identifier의 값들을 fetch하고 제목과 calendar가 같다면 continue
                    var isContinue = false
                    reminderCollection?.forEach({ (value) in
                        guard let identifier = (value as? Reminder)?.identifier,
                            let existReminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder,
                            existReminder.title == reminder.title else { return }
                        
                        if let calendar = reminder.calendar {
                            let alarm = EKAlarm(absoluteDate: calendar.startDate)
                            existReminder.alarms = [alarm]
                        } else {
                            existReminder.alarms = []
                        }
                        isContinue = true
                        
                    })
                    
                    if isContinue {
                        //이미 기존꺼와 중복이 되는 것이므로 아래꺼는 실행시키지 않는다.
                        continue
                    }
                    
                    
                    //리마인더를 만들어줘서 identifier를 get해야함
                    let ekReminder = EKReminder(eventStore: eventStore)
                    ekReminder.title = reminder.title
                    if let calendar = reminder.calendar {
                        ekReminder.title = calendar.title
                        let alarm = EKAlarm(absoluteDate: calendar.startDate)
                        ekReminder.addAlarm(alarm)
                    }
                    ekReminder.calendar = eventStore.defaultCalendarForNewReminders()
                    ekReminder.isCompleted = reminder.isCompleted
                    
                    if let context = managedObjectContext {
                        let cdReminder = Reminder(context: context)
                        cdReminder.identifier = ekReminder.calendarItemExternalIdentifier
                        cdReminder.addToNoteCollection(self)
                    }
                    
                    try eventStore.save(ekReminder, commit: false)
                    continue
                    
                } else if let calendar = paraString.calendar() {
                    //eventCollection을 돌아서 identifier의 값들을 fetch하고 제목이 같다면 continue
                    var isContinue = false
                    eventCollection?.forEach({ (value) in
                        guard let identifier = (value as? Event)?.identifier,
                            let existEvent = eventStore.calendarItem(withIdentifier: identifier) as? EKEvent,
                            existEvent.title == calendar.title else { return }
                        
                        if existEvent.startDate != calendar.startDate || existEvent.endDate != calendar.endDate {
                            existEvent.startDate = calendar.startDate
                            existEvent.endDate = calendar.endDate
                        }
                        isContinue = true
                    })
                    
                    if isContinue {
                        //이미 기존꺼와 중복이 되는 것이므로 아래꺼는 실행시키지 않는다.
                        continue
                    }
                    
                    
                    
                    //캘린더를 만들어줘서 identifier를 get해야함
                    let ekEvent = EKEvent(eventStore: eventStore)
                    ekEvent.title = calendar.title
                    ekEvent.startDate = calendar.startDate
                    ekEvent.endDate = calendar.endDate
                    ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                    
                    if let context = self.managedObjectContext {
                        let cdEvent = Event(context: context)
                        cdEvent.identifier = ekEvent.calendarItemExternalIdentifier
                        cdEvent.addToNoteCollection(self)
                    }
                    
                    try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: false)
                    continue
                    
                } else if let contact = paraString.contact() {
                    //contactCollection을 돌아서 identifier의 값들을 fetch하고 이름이 같다면 수정 continue
                    var isContinue = false
                    
                    /// 연락처에서 가져오고자 하는 Key의 집합.
                    let CNContactFetchKeys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor,
                                                                 CNContactFamilyNameKey as CNKeyDescriptor,
                                                                 CNContactPhoneNumbersKey as CNKeyDescriptor,
                                                                 CNContactEmailAddressesKey as CNKeyDescriptor,
                                                                 CNContactUrlAddressesKey as CNKeyDescriptor,
                                                                 CNContactViewController.descriptorForRequiredKeys()]
                    
                    do {
                        try contactCollection?.forEach({ (value) in
                            guard let identifier = (value as? Contact)?.identifier,
                                let existContact = try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: CNContactFetchKeys).mutableCopy() as? CNMutableContact else { return }
                            
                            if existContact.givenName == contact.givenName && existContact.familyName == contact.familyName {
                                contact.phones.forEach({ (phone) in
                                    let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberiPhone,
                                                                     value: CNPhoneNumber(stringValue: phone))
                                    existContact.phoneNumbers.append(phoneNumber)
                                    
                                })
                                
                                contact.addresses.forEach({ (key, string) in
                                    let address = CNMutablePostalAddress()
                                    switch key {
                                    case .street:
                                        address.street = string
                                    case .city:
                                        address.city = string
                                    case .state:
                                        address.state = string
                                    case .country:
                                        address.country = string
                                    case .zip:
                                        address.postalCode = string
                                    default:
                                        return
                                    }
                                    
                                    let value = CNLabeledValue<CNPostalAddress>(label:CNLabelWork, value: address)
                                    existContact.postalAddresses.append(value)
                                })
                                
                                contact.mails.forEach({ (mail) in
                                    let workEmail = CNLabeledValue(label:CNLabelWork, value: mail as NSString)
                                    existContact.emailAddresses.append(workEmail)
                                })
                                
                                isContinue = true
                            }
                        })
                    } catch {
                        print("전번 비교하는 로직 에러: \(error.localizedDescription)")
                    }

                    if isContinue {
                        //이미 기존꺼와 중복이 되는 것이므로 아래꺼는 실행시키지 않는다.
                        continue
                    }
                    
                    
                    //연락처 만들어줘서 identifier를 get해야함
                    let cnContact = CNMutableContact()
                    cnContact.givenName = contact.givenName
                    cnContact.familyName = contact.familyName
                    
                    contact.phones.forEach { (phone) in
                        let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberiPhone,
                                                         value: CNPhoneNumber(stringValue: phone))
                        cnContact.phoneNumbers.append(phoneNumber)
                    }
                    
                    contact.addresses.forEach { (key, string) in
                        let address = CNMutablePostalAddress()
                        switch key {
                        case .street:
                            address.street = string
                        case .city:
                            address.city = string
                        case .state:
                            address.state = string
                        case .country:
                            address.country = string
                        case .zip:
                            address.postalCode = string
                        default:
                            return
                        }
                        
                        let value = CNLabeledValue<CNPostalAddress>(label:CNLabelWork, value: address)
                        cnContact.postalAddresses.append(value)
                    }
                    
                    contact.mails.forEach { (mail) in
                        let workEmail = CNLabeledValue(label:CNLabelWork, value: mail as NSString)
                        cnContact.emailAddresses.append(workEmail)
                    }
                    
                    if let context = self.managedObjectContext {
                        let cdContact = Contact(context: context)
                        cdContact.identifier = cnContact.identifier
                        cdContact.addToNoteCollection(self)
                    }
                    
                    let saveRequest = CNSaveRequest()
                    saveRequest.add(cnContact, toContainerWithIdentifier: Util.share.getUniqueID())
                    
                    try contactStore.execute(saveRequest)
                    continue
                }
                
            }
            
            self.saveIfNeeded()
            try eventStore.commit()
        } catch {
            print("error in connectData: \(error.localizedDescription)")
        }
    }
}
