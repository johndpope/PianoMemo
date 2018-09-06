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
        fetch()
    }
    
}

extension ContactPickerTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
        request.sortOrder = .userDefault
        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
            self.fetchedContacts.append(contact)
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
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let contactCollection = note?.contactCollection else {return}
        let selectedContactID = fetchedContacts[indexPath.row].identifier
        switch contactCollection.contains(where: {($0 as! Contact).identifier == selectedContactID}) {
        case true: unlink(at: indexPath)
        case false: link(at: indexPath)
        }
    }
    
    private func link(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        let selectedContact = fetchedContacts[indexPath.row]
        let localContact = Contact(context: viewContext)
        localContact.identifier = selectedContact.identifier
        note.addToContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let note = note, let viewContext = note.managedObjectContext else {return}
        guard let contactCollection = note.contactCollection else {return}
        let selectedContact = fetchedContacts[indexPath.row]
        for localContact in contactCollection {
            guard let localContact = localContact as? Contact else {continue}
            if localContact.identifier == selectedContact.identifier {
                note.removeFromContactCollection(localContact)
                break
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}
