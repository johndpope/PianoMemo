//
//  ContactTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import ContactsUI

/// 연락처에서 가져오고자 하는 Key의 집합.
let CNContactFetchKeys: [CNKeyDescriptor] = [
    CNContactGivenNameKey as CNKeyDescriptor,
    CNContactFamilyNameKey as CNKeyDescriptor,
    CNContactPhoneNumbersKey as CNKeyDescriptor,
    CNContactEmailAddressesKey as CNKeyDescriptor,
    CNContactUrlAddressesKey as CNKeyDescriptor,
    CNContactViewController.descriptorForRequiredKeys()
]

class ContactViewController: UIViewController {
   
    @IBOutlet weak var tableView: UITableView!
    
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }
    
    private let contactStore = CNContactStore()
    private var fetchedContacts = [CNContact]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.titleView = nil
        tabBarController?.title = "contact".loc
        let rightBarBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem(_:)))
        tabBarController?.navigationItem.setRightBarButtonItems([rightBarBtn], animated: true)
        auth {self.fetch()}
    }
    
    @objc private func addItem(_ button: UIBarButtonItem) {
        performSegue(withIdentifier: "ContactPickerTableViewController", sender: nil)
    }
    
    private func auth(_ completion: @escaping (() -> ())) {
        CNContactStore().requestAccess(for: .contacts) { status, error in
            DispatchQueue.main.async {
                switch status {
                case true: completion()
                case false: self.alert()
                }
            }
        }
    }
    
    private func alert() {
        let alert = UIAlertController(title: nil, message: "permission_contact".loc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let contactPVC = segue.destination as? ContactPickerTableViewController else {return}
        contactPVC.note = note
    }
    
}

extension ContactViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            self.requestSuggestions()
        }
    }
    
    private func request() {
        guard let contactCollection = note.contactCollection else {return}
        fetchedContacts.removeAll()
        for localContact in contactCollection {
            guard let localContact = localContact as? Contact, let id = localContact.identifier else {continue}
            guard let contact = try? contactStore.unifiedContact(withIdentifier: id, keysToFetch: CNContactFetchKeys) else {continue}
            fetchedContacts.append(contact)
        }
        purge()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func purge() {
        guard let viewContext = note.managedObjectContext else {return}
        guard let contactCollection = note.contactCollection else {return}
        for contact in contactCollection {
            guard let contact = contact as? Contact else {return}
            if !fetchedContacts.contains(where: {$0.identifier == contact.identifier}) {
                note.removeFromContactCollection(contact)
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
    private func requestSuggestions() {
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
        guard let noteContent = note.content else { return }

        let noteTokens = noteContent.tokenzied
        let integerableToken = noteTokens.filter { Int($0) != nil }.joined()

        var contacts = [CNContact]()

        let request = CNContactFetchRequest(keysToFetch: keys)
        try? contactStore.enumerateContacts(with: request) { contact, pointer in
            var didAppendContact = false

            if let fullName = CNContactFormatter.string(from: contact, style: .fullName) {
                let nameTokens = fullName.tokenzied
                for token in noteTokens {
                    if nameTokens.contains(token) {
                        contacts.append(contact)
                        didAppendContact = true
                        break
                    }
                }
            }

            if didAppendContact == false,
                let phoneticFullName = CNContactFormatter.string(from: contact, style: .phoneticFullName) {
                let nameTokens = phoneticFullName.tokenzied
                for token in noteTokens {
                    if nameTokens.contains(token) {
                        contacts.append(contact)
                        didAppendContact = true
                        break
                    }
                }
            }

            // (011) 111-1111 형태로 저장된 전화 번호는 스트링 토큰 형태로 다룰 수 있지만,
            // 111222333 형태로 저장된 전화 번호는 다른 방법을 써야 한다.
            // 노트 전체의 숫자를 스트링으로 만들고, 스트링 range를 사용해서 검색한다.
            if didAppendContact == false {
                let numberStringRepresentations = contact.phoneNumbers
                    .map { ($0.value as CNPhoneNumber) }
                    .flatMap { $0.stringValue.components(separatedBy: .punctuationCharacters)
                        .filter { $0.count > 0 }
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    }

                let numberSet = Set(numberStringRepresentations)
                var containCounter = 0

                // (011) 111-1111로 저장된 경우
                // 일치하는 토큰이 두 개 이상이면 추천할 연락처로 판단한다.
                for token in noteTokens {
                    if numberSet.contains(token) {
                        containCounter += 1
                    }
                    if containCounter > 1 {
                        contacts.append(contact)
                        didAppendContact = true
                        break
                    }
                }

                // 111222333 형태로 저장된 경우
                if didAppendContact == false {
                    for number in numberSet {
                        if integerableToken.range(of: number) != nil {
                            contacts.append(contact)
                            didAppendContact = true
                            break
                        } else if number.range(of: integerableToken) != nil {
                            contacts.append(contact)
                            didAppendContact = true
                            break
                        }
                    }
                }
            }

            if didAppendContact == false {
                let usernameComponents = contact.emailAddresses
                    .compactMap { ($0.value as NSString)
                        .components(separatedBy: "@")
                        .first
                    }
                    .flatMap { $0.components(separatedBy: .punctuationCharacters) }

                for token in noteTokens {
                    if usernameComponents.contains(token) {
                        contacts.append(contact)
                        break
                    }
                }
            }
        }

        DispatchQueue.main.async {
            // TODO: 추천 결과 이용해서 UI 업데이트 하기
        }
        print("\n추천할 연락처 갯수: \(contacts.count)")
        print(noteTokens)
        print(contacts.map { $0.givenName })
    }
}

extension ContactViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell") as! ContactTableViewCell
        cell.configure(fetchedContacts[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        open(with: fetchedContacts[indexPath.row])
    }
    
    private func open(with contact: CNContact) {
        let contactVC = CNContactViewController(for: contact)
        contactVC.contactStore = contactStore
        navigationController?.pushViewController(contactVC, animated: true)
    }
    
}

extension ContactViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {return}
        unlink(at: indexPath)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        let contact = fetchedContacts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        guard let localContact = note.contactCollection?.first(where: {($0 as! Contact).identifier == contact.identifier}) as? Contact else {return}
        note.removeFromContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

