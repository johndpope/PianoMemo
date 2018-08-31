//
//  ContactSuggestionTableView.swift
//  Light
//
//  Created by hoemoon on 31/08/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Contacts

protocol ContactSuggestionDelegate: class {
    func refreshContactDate()
}

class ContactSuggestionTableView: UITableView {
    @IBOutlet weak var headerView: SuggestionTableHeaderView!
    weak var note: Note!
    weak var refreshDelegate: ContactSuggestionDelegate!
    let headerHeight: CGFloat = 50
    private var contacts = [CNContact]()

    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = self
        delegate = self
        rowHeight = 50
        backgroundColor = .white
        separatorStyle = .none
        translatesAutoresizingMaskIntoConstraints = false
    }

    func setupDataSource(_ dataSource: [CNContact]) {
        self.contacts = dataSource
        headerView.configure(title: "Suggestion", count: dataSource.count)
    }
}

extension ContactSuggestionTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell", for: indexPath) as? ContactTableViewCell {
            cell.configure(contacts[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }

}

extension ContactSuggestionTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewContext = note.managedObjectContext else {return}
        let contact = contacts[indexPath.row]
        let localContact = Contact(context: viewContext)
        localContact.identifier = contact.identifier
        localContact.createdDate = Date()
        localContact.modifiedDate = Date()
        note.addToContactCollection(localContact)
        if viewContext.hasChanges {try? viewContext.save()}
        contacts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        refreshDelegate.refreshContactDate()
    }

}
