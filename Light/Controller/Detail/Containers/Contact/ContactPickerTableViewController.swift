//
//  ContactPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import ContactsUI

class ContactPickerTableViewController: UITableViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private let contactStore = CNContactStore()
    private var fetchedContacts = [[String : [CNContact]]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        fetch()
    }
    
}

extension ContactPickerTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
        request.sortOrder = .userDefault
        var tempContacts = [CNContact]()
        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
            tempContacts.append(contact)
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
    }
    
    private func name(from contact: CNContact) -> String {
        if !contact.givenName.isEmpty {
            return contact.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if !contact.familyName.isEmpty {
            return contact.familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return contact.departmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
}

extension ContactPickerTableViewController {
    
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
        selection(cell: indexPath)
        cell.cellDidSelected = {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        cell.contentDidSelected = {
            self.open(with: contact)
        }
        return cell
    }
    
    private func selection(cell indexPath: IndexPath) {
        guard let contactCollection = note?.contactCollection else {return}
        guard let secTitle = fetchedContacts[indexPath.section].keys.first else {return}
        guard let targetContact = fetchedContacts[indexPath.section][secTitle]?[indexPath.row] else {return}
        switch contactCollection.contains(where: {($0 as! Contact).identifier == targetContact.identifier}) {
        case true: tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        case false: tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    private func open(with contact: CNContact) {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = false
        contactVC.contactStore = contactStore
        navigationController?.pushViewController(contactVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle(rawValue: 3) ?? .insert
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        manageLink(indexPath)
    }
    
    private func manageLink(_ indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let contactCollection = note.contactCollection else {return}
        guard let secTitle = fetchedContacts[indexPath.section].keys.first else {return}
        guard let selectedContact = fetchedContacts[indexPath.section][secTitle]?[indexPath.row] else {return}
        switch contactCollection.contains(where: {($0 as! Contact).identifier == selectedContact.identifier}) {
        case true:
            for localContact in contactCollection {
                guard let localContact = localContact as? Contact else {continue}
                guard  localContact.identifier == selectedContact.identifier else {continue}
                note.removeFromContactCollection(localContact)
                break
            }
        case false:
            let localContact = Contact(context: viewContext)
            localContact.identifier = selectedContact.identifier
            note.addToContactCollection(localContact)
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}
