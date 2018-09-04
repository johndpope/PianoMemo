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

class ContactTableViewController: UITableViewController, ContainerDatasource {
    
    var note: Note? {
        get {
            return (navigationController?.parent as? DetailViewController)?.note
        } set {
            (navigationController?.parent as? DetailViewController)?.note = newValue
        }
    }
    
    private let contactStore = CNContactStore()
    private var fetchedContacts = [CNContact]()
    
    internal func reset() {
        fetchedContacts = []
        tableView.reloadData()
    }
    
    internal func startFetch() {
        auth {self.fetch()}
    }
    
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {return}
        unlink(at: indexPath)
    }
    
    private func unlink(at indexPath: IndexPath) {
        guard let note = note,
            let viewContext = note.managedObjectContext else {return}
        let contact = fetchedContacts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        guard let localContact = note.contactCollection?.first(where: {($0 as! Contact).identifier == contact.identifier}) as? Contact else {return}
        note.removeFromContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
    }

}

extension ContactTableViewController {
    
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
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let note = note,
            let contactCollection = note.contactCollection else {return}
        fetchedContacts.removeAll()
        for localContact in contactCollection {
            guard let localContact = localContact as? Contact, let id = localContact.identifier else {continue}
            guard let contact = try? contactStore.unifiedContact(withIdentifier: id, keysToFetch: CNContactFetchKeys) else {continue}
            fetchedContacts.append(contact)
        }
        purge()
    }
    
    private func purge() {
        guard let note = note,
            let viewContext = note.managedObjectContext,
            let contactCollection = note.contactCollection else {return}
        for localContact in contactCollection {
            guard let localContact = localContact as? Contact else {return}
            if !fetchedContacts.contains(where: {$0.identifier == localContact.identifier}) {
                note.removeFromContactCollection(localContact)
            }
        }
        if viewContext.hasChanges {try? viewContext.save()}
    }
                
}
