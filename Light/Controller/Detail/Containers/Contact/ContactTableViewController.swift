//
//  ContactTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 3..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import ContactsUI

/// 연락처에서 가져오고자 하는 Key의 집합.
let CNContactFetchKeys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor,
                                             CNContactFamilyNameKey as CNKeyDescriptor,
                                             CNContactPhoneNumbersKey as CNKeyDescriptor,
                                             CNContactEmailAddressesKey as CNKeyDescriptor,
                                             CNContactUrlAddressesKey as CNKeyDescriptor,
                                             CNContactViewController.descriptorForRequiredKeys()]

class ContactTableViewController: UITableViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private let contactStore = CNContactStore()
    private var fetchedContacts = [[String : [CNContact]]]()
    
    var isNeedFetch = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isNeedFetch else {return}
        isNeedFetch = false
        startFetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ContactPickerTableViewController" {
            guard let pickerVC = segue.destination as? ContactPickerTableViewController else {return}
            pickerVC.contactVC = self
        }
    }
    
}

extension ContactTableViewController: ContainerDatasource {
    
    func reset() {
        fetchedContacts.removeAll()
    }
    
    func startFetch() {
        authAndFetch()
    }
    
}

extension ContactTableViewController {
    
    private func authAndFetch() {
        CNContactStore().requestAccess(for: .contacts) { (status, error) in
            DispatchQueue.main.async {
                switch status {
                case true: self.fetch()
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
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        guard let note = note, let contactCollection = note.contactCollection else {return}
        fetchedContacts.removeAll()
        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
        request.sortOrder = .userDefault
        var tempContacts = [CNContact]()
        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
            if contactCollection.contains(where: {($0 as! Contact).identifier == contact.identifier}) {
                tempContacts.append(contact)
            }
        }
        var tempSecContacts = [[String : [CNContact]]]()
        for contact in tempContacts {
            let secTitle = String(name(from: contact).first!)
            if let index = tempSecContacts.index(where: {$0.keys.first == secTitle}) {
                tempSecContacts[index][secTitle]?.append(contact)
            } else {
                tempSecContacts.append([secTitle : [contact]])
            }
        }
        fetchedContacts = tempSecContacts.sorted(by: {$0.keys.first! < $1.keys.first!})
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
        purge()
    }
    
    private func name(from contact: CNContact) -> String {
        if !contact.familyName.isEmpty {
            return contact.familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if !contact.givenName.isEmpty {
            return contact.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return contact.departmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func purge() {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let contactCollection = note.contactCollection else {return}
        var noteContactsToDelete: [Contact] = []
        for localContact in contactCollection {
            guard let localContact = localContact as? Contact, let id = localContact.identifier else {continue}
            do {
                try contactStore.unifiedContact(withIdentifier: id, keysToFetch: CNContactFetchKeys)
            } catch {
                noteContactsToDelete.append(localContact)
            }
        }
        noteContactsToDelete.forEach {viewContext.delete($0)}
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension ContactTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedContacts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedContacts[section].values.first?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedContacts[section].keys.first ?? ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell") as! ContactTableViewCell
        guard let contact = fetchedContacts[indexPath.section].values.first?[indexPath.row] else {return UITableViewCell()}
        cell.configure(contact)
        cell.cellDidSelected = {tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)}
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let secTitle = fetchedContacts[indexPath.section].keys.first else {return}
        guard let selectedContact = fetchedContacts[indexPath.section][secTitle]?[indexPath.row] else {return}
        open(with: selectedContact)
    }
    
    private func open(with contact: CNContact) {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = false
        contactVC.contactStore = contactStore
        navigationController?.pushViewController(contactVC, animated: true)
    }
    
}
