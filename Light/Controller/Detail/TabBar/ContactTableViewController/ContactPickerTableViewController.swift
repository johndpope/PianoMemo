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
    
    var note: Note!
    
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
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        //        guard let contactCollection = note.contactCollection else {return}
        fetchedContacts.removeAll()
        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
            //            if !contactCollection.contains(where: {($0 as! Contact).identifier == contact.identifier}) {
            self.fetchedContacts.append(contact)
            //            }
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
        cell.configure(contact, isLinked: note.contactCollection?.contains(contact))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let contactCollection = note.contactCollection else {return}
        let contact = fetchedContacts[indexPath.row]
        switch contactCollection.contains(where: {($0 as! Contact).identifier == contact.identifier}) {
        case true: unlink(at: indexPath)
        case false: link(at: indexPath)
        }
    }
    
    private func link(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        //        let contact = fetchedContacts.remove(at: indexPath.row)
        //        tableView.deleteRows(at: [indexPath], with: .fade)
        let contact = fetchedContacts[indexPath.row]
        let localContact = Contact(context: viewContext)
        localContact.identifier = contact.identifier
        localContact.createdDate = Date()
        localContact.modifiedDate = Date()
        note.addToContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        guard let contactCollection = note.contactCollection else {return}
        let selectedContact = fetchedContacts[indexPath.row]
        for contact in contactCollection {
            guard let contact = contact as? Contact else {return}
            if contact.identifier == selectedContact.identifier {
                note.removeFromContactCollection(contact)
                break
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
}


