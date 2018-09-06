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
    private var fetchedContacts = [CNContact]()
    
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
        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
            self.fetchedContacts.append(contact)
        }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
}

extension ContactPickerTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedContacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell") as! ContactTableViewCell
        let contact = fetchedContacts[indexPath.row]
        cell.configure(contact, isLinked: note?.contactCollection?.contains(contact))
        selection(cell: indexPath)
        cell.cellDidSelected = {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        cell.contentDidSelected = {
            
        }
        return cell
    }
    
    private func selection(cell indexPath: IndexPath) {
        guard let contactCollection = note?.contactCollection else {return}
        let targetContact = fetchedContacts[indexPath.row]
        switch contactCollection.contains(where: {($0 as! Contact).identifier == targetContact.identifier}) {
        case true: tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        case false: tableView.deselectRow(at: indexPath, animated: false)
        }
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
        let selectedContact = fetchedContacts[indexPath.row]
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
