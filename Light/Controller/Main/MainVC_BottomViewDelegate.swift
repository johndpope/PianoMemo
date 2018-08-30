//
//  MainVC_BottomViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import EventKit
import Contacts

extension MainViewController: BottomViewDelegate {
    func bottomView(_ bottomView: BottomView, keyboardWillHide height: CGFloat) {
        setEditButtonIfNeeded()
    }
    
    func bottomView(_ bottomView: BottomView, keyboardWillShow height: CGFloat) {
        setDoneButtonIfNeeded()
    }
    
    func bottomView(_ bottomView: BottomView, didFinishTyping text: String) {
        createNote(text: text)
    }
    
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        typingCounter += 1
        perform(#selector(requestQuery(_:)), with: textView.text, afterDelay: searchRequestDelay)
    }
    
}

extension MainViewController {
    
    
    /// persistent store에 검색 요청하는 메서드.
    /// 검색할 문자열의 길이가 30보다 작을 경우,
    /// 0.3초 이상 멈추는 경우에만 실제로 요청한다.
    ///
    /// - Parameter sender: 검색할 문자열
    @objc func requestQuery(_ sender: Any?) {
        typingCounter -= 1
        guard let text = sender as? String,
            typingCounter == 0,
            text.count < 30  else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.refreshFetchRequest(with: text)
        }
    }

    private func refreshFetchRequest(with text: String) {
        guard text.count != 0 else {
            noteFetchRequest.predicate = nil
            refreshCollectionView()
            return
        }
        noteFetchRequest.predicate = text.predicate(fieldName: "content")
        refreshCollectionView()
    }

    private func saveContext() {
        if mainContext.hasChanges {
            do {
                try mainContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // for test
    func setupDummyNotes() {
        try? resultsController?.performFetch()
        if resultsController?.fetchedObjects?.count ?? 0 < 100 {
            for _ in 1...50000 {
                let note = Note(context: mainContext)
                note.content = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Aenean lacinia bibendum nulla sed consectetur. Nullam id dolor id nibh ultricies vehicula ut id elit. Donec sed odio dui. Nullam quis risus eget urna mollis ornare vel eu leo."
            }
            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "👻 apple Nullam id dolor id nibh ultricies vehicula ut id elit."
            }

            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "👻 bang Maecenas faucibus mollis interdum."
            }

            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "한글을 입력해서 더미 데이터를 만들어보자."
            }


            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "한글을 두드려서 더미 data를 만들자."
            }

            saveContext()
            try? resultsController?.performFetch()
        }
    }
}

extension MainViewController {
    
    enum BarButtonType: Int {
        case edit = 0
        case done = 1
    }
    
    private func setDoneButtonIfNeeded() {
        if navigationItem.rightBarButtonItem == nil {
            setDoneBtn()
            return
        }
        
        if let rightBarItem = navigationItem.rightBarButtonItem,
            let type = BarButtonType(rawValue: rightBarItem.tag),
            type != .done {
            setDoneBtn()
            return
        }
        
    }
    
    private func setEditButtonIfNeeded() {
        if navigationItem.rightBarButtonItem == nil {
            setEditBtn()
        }
        
        if let rightBarItem = navigationItem.rightBarButtonItem,
            let type = BarButtonType(rawValue: rightBarItem.tag),
            type != .edit {
            setEditBtn()
        }
    }
    
    @IBAction func done(_ sender: Any) {
        
    }
    
    @IBAction func edit(_ sender: Any) {
        
    }
    
    private func createNote(text: String) {
        let note = Note(context: mainContext)
        note.content = text
        note.createdDate = Date()
        note.modifiedDate = Date()
        
        connectData(to: note)
        
        
        saveContext()
    }
    
    private func connectData(to note: Note) {
        guard let text = note.content else { return }
        do {
            let eventStore = EKEventStore()
            let contactStore = CNContactStore()
            let paraArray = text.components(separatedBy: .newlines)
            for paraString in paraArray {
                //아래의 순서로 진행하여야 함
                if let reminder = paraString.reminder() {
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
                    
                    if let context = note.managedObjectContext {
                        let cdReminder = Reminder(context: context)
                        cdReminder.identifier = ekReminder.calendarItemExternalIdentifier
                        cdReminder.addToNoteCollection(note)
                    }
                    
                    try eventStore.save(ekReminder, commit: false)
                    continue
                    
                } else if let calendar = paraString.calendar() {
                    //캘린더를 만들어줘서 identifier를 get해야함
                    let ekEvent = EKEvent(eventStore: eventStore)
                    ekEvent.title = calendar.title
                    ekEvent.startDate = calendar.startDate
                    ekEvent.endDate = calendar.endDate
                    ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                    
                    if let context = note.managedObjectContext {
                        let cdEvent = Event(context: context)
                        cdEvent.identifier = ekEvent.calendarItemExternalIdentifier
                        cdEvent.addToNoteCollection(note)
                    }
                    
                    try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: false)
                    continue
                    
                } else if let contact = paraString.contact() {
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
                    
                    if let context = note.managedObjectContext {
                        let cdContact = Contact(context: context)
                        cdContact.identifier = cnContact.identifier
                        cdContact.addToNoteCollection(note)
                    }
                    
                    let saveRequest = CNSaveRequest()
                    saveRequest.add(cnContact, toContainerWithIdentifier: Util.share.getUniqueID())
                    
                    try contactStore.execute(saveRequest)
                    continue
                }
                
            }
            
            note.saveIfNeeded()
            try eventStore.commit()
        } catch {
            print("error in connectData: \(error.localizedDescription)")
        }
        
        
        
    }
    
    enum ConnectType {
        case reminder
        case calendar
        case contact
        case phoneNum
        case address
        case mail
    }
    

}

extension MainViewController {
    private func setDoneBtn(){
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        doneBtn.tag = 1
        navigationItem.setRightBarButton(doneBtn, animated: true)
    }
    
    private func setEditBtn(){
        let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        editBtn.tag = 0
        navigationItem.setRightBarButton(editBtn, animated: true)
    }
}
