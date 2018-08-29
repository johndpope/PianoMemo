//
//  ContactPickerTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
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
        fetchedContacts.removeAll()
        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
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
        cell.configure(fetchedContacts[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        insert(at: indexPath)
    }
    
    private func insert(at indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        let contact = fetchedContacts[indexPath.row]
        let localContact = Contact(context: viewContext)
        localContact.identifier = contact.identifier
        localContact.createdDate = Date()
        localContact.modifiedDate = Date()
        note.addToContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
        navigationController?.popViewController(animated: true)
    }
    
}
