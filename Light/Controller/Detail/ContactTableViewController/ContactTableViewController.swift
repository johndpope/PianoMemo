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
//        guard let contactCollection = note.contactCollection else {return}
//        let request = CNContactFetchRequest(keysToFetch: CNContactFetchKeys)
//        try? self.contactStore.enumerateContacts(with: request) { (contact, error) in
//
//        }
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

