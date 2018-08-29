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
let CNContactFetchKeys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor,
                                             CNContactFamilyNameKey as CNKeyDescriptor,
                                             CNContactPhoneNumbersKey as CNKeyDescriptor,
                                             CNContactEmailAddressesKey as CNKeyDescriptor,
                                             CNContactUrlAddressesKey as CNKeyDescriptor,
                                             CNContactViewController.descriptorForRequiredKeys()]

class ContactTableViewController: UITableViewController {
    
    var note: Note!
    
    private let contactStore = CNContactStore()
    private var fetchedContacts = [CNContact]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetch()
    }
    
    @IBAction private func close(_ button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction private func addItem(_ button: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let createAction = UIAlertAction(title: "create".loc, style: .default) { _ in
            self.newContact()
        }
        let importAction = UIAlertAction(title: "import".loc, style: .default) { _ in
            self.performSegue(withIdentifier: "ContactPickerTableViewController", sender: nil)
        }
        let cancelAction = UIAlertAction(title: "cencel".loc, style: .cancel)
        alert.addAction(createAction)
        alert.addAction(importAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let contactPVC = segue.destination as? ContactPickerTableViewController else {return}
        contactPVC.note = note
    }
    
}

extension ContactTableViewController: CNContactViewControllerDelegate {
    
    private func newContact() {
        let contactVC = CNContactViewController(forNewContact: nil)
        contactVC.contactStore = contactStore
        contactVC.delegate = self
        present(UINavigationController(rootViewController: contactVC), animated: true)
    }
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if let contact = contact {
            insert(with: contact)
        }
        viewController.dismiss(animated: true)
    }
    
    private func insert(with contact: CNContact) {
        guard let viewContext = note.managedObjectContext else {return}
        let localContact = Contact(context: viewContext)
        localContact.identifier = contact.identifier
        localContact.createdDate = Date()
        localContact.modifiedDate = Date()
        note.addToContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            self.purge()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let contactCollection = note.contactCollection else {return}
        fetchedContacts.removeAll()
        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
            if contactCollection.contains(where: {($0 as! Contact).identifier == contact.identifier}) {
                self.fetchedContacts.append(contact)
            }
        }
    }
    
    private func purge() {
        guard let viewContext = note.managedObjectContext else {return}
        guard let contactCollection = note.contactCollection else {return}
        for contact in contactCollection {
            if let contact = contact as? Contact {
                if !fetchedContacts.contains(where: {$0.identifier == contact.identifier}) {
                    note.removeFromContactCollection(contact)
                }
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
    
}

extension ContactTableViewController {
    
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
        open(with: fetchedContacts[indexPath.row])
    }
    
    private func open(with contact: CNContact) {
        let contactVC = CNContactViewController(for: contact)
        contactVC.contactStore = contactStore
        navigationController?.pushViewController(contactVC, animated: true)
    }
    
}

extension ContactTableViewController {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
