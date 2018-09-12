//
//  ContactPickerCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 11..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import ContactsUI

class ContactPickerCollectionViewController: UICollectionViewController, NoteEditable {

    var note: Note!
    var mainContext: NSManagedObjectContext!
    let contactStore = CNContactStore()
    var identifiersToDelete: [String] = []
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView?.reloadData()
                self?.selectCollectionViewForConnectedContact()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.allowsMultipleSelection = true
        
        appendContactsToDataSource()
    }

}

extension ContactPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        let identifiersToAdd = collectionView?.indexPathsForSelectedItems?.compactMap({ (indexPath) -> String? in
            return (dataSource[indexPath.section][indexPath.item] as? ContactViewModel)?.contact.identifier
        })
        
        guard let privateContext = note.managedObjectContext else { return }
        
        privateContext.perform { [ weak self ] in
            guard let `self` = self else { return }
            
            if let identifiersToAdd = identifiersToAdd {
                identifiersToAdd.forEach { identifier in
                    if !self.note.contactIdentifiers.contains(identifier) {
                        let contact = Contact(context: privateContext)
                        contact.identifier = identifier
                        contact.addToNoteCollection(self.note)
                    }
                }
            }
            
            self.identifiersToDelete.forEach { identifier in
                guard let contact = self.note.contactCollection?.filter({ (value) -> Bool in
                    guard let contact = value as? Contact,
                        let existIdentifier = contact.identifier else { return false }
                    return identifier == existIdentifier
                }).first as? Contact else { return }
                privateContext.delete(contact)
            }
            
            privateContext.saveIfNeeded()
            self.mainContext.performAndWait {
                self.mainContext.saveIfNeeded()
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension ContactPickerCollectionViewController {
    private func selectCollectionViewForConnectedContact(){
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            
            self.dataSource.enumerated().forEach({ (section, collectionDatas) in
                collectionDatas.enumerated().forEach({ (item, collectionData) in
                    guard let contactViewModel = collectionData as? ContactViewModel else { return }
                    if self.note.contactIdentifiers.contains(contactViewModel
                        .contact
                        .identifier) {
                        let indexPath = IndexPath(item: item, section: section)
                        DispatchQueue.main.async {
                            self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
                        }
                    }
                })
            })
            
        }
    }
    
    private func appendContactsToDataSource() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { [weak self] (status, error) in
                switch status {
                case true: self?.fetchContacts()
                case false: self?.alert()
                }
            }
        case .authorized: fetchContacts()
        case .restricted, .denied: alert()
        }
    }
    
    private func fetchContacts() {
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactViewController.descriptorForRequiredKeys()
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        var containerIdentifiers: Set<String> = [contactStore.defaultContainerIdentifier()]
        
        var results: [CNContact] = []
        
        do {
            let containers = try contactStore.containers(matching: nil).map { $0.identifier }
            containerIdentifiers = containerIdentifiers.intersection(containers)
            
            containerIdentifiers.forEach { (identifier) in
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: identifier)
                do {
                    let result = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
                    results.append(contentsOf: result)
                } catch {
                    print("predicate으로 연락처 가져오는 도중 에러: \(error.localizedDescription)")
                }
                
            }
        } catch {
            print("연락처 컨테이너 가져오는 도중에 에러: \(error.localizedDescription)")
        }
        
        let contactViewModels = results.map { (cnContact) -> ContactViewModel in
            return ContactViewModel(contact: cnContact, infoAction: { [weak self] in
                guard let `self` = self else { return }
                let contactVC = CNContactViewController(for: cnContact)
                contactVC.allowsEditing = true
                contactVC.contactStore = self.contactStore
                self.navigationController?.pushViewController(contactVC, animated: true)
                }, contactStore: contactStore)
        }
        
        dataSource.append(contactViewModels)
        
    }
    
    private func alert() {
        let alert = UIAlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
        let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
    }
}

extension ContactPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.identifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
        cell.data = data
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    //    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    //        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? "DetailIVCollectionReusableView", for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
    //        reusableView.data = dataSource[indexPath.section][indexPath.item]
    //        return reusableView
    //    }
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    //        return dataSource[section].first?.headerSize ?? CGSize.zero
    //    }
}

extension ContactPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? ContactViewModel else { return }
        
        if let index = identifiersToDelete.index(of: viewModel.contact.identifier) {
            identifiersToDelete.remove(at: index)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
        
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? ContactViewModel else { return }
        let identifier = viewModel.contact.identifier
        if note.contactIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension ContactPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maximumWidth = collectionView.bounds.width - (collectionView.marginLeft + collectionView.marginRight)
        return dataSource[indexPath.section][indexPath.item].size(maximumWidth: maximumWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
