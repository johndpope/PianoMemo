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

class ContactPickerCollectionViewController: UICollectionViewController, CollectionRegisterable {

    let contactStore = CNContactStore()
    var identifiersToDelete: [String] = []
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerHeaderView(PianoReusableView.self)
        registerCell(CNContactCell.self)
        collectionView?.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        
        Access.contactRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            self.appendContactsToDataSource()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self](context) in
            guard let `self` = self else { return }
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
}

extension ContactPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}

extension ContactPickerCollectionViewController {
    
    private func appendContactsToDataSource() {
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
        
        dataSource.append(results)
    }
    

}

extension ContactPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
        cell.data = data
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//            var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
//            reusableView.data = dataSource[indexPath.section][indexPath.item]
//            return reusableView
//        }
//    
//        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//            return dataSource[section].first?.headerSize ?? CGSize.zero
//        }
}

extension ContactPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cnContact = dataSource[indexPath.section][indexPath.item] as? CNContact else { return }
        if let index = identifiersToDelete.index(of: cnContact.identifier) {
            identifiersToDelete.remove(at: index)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

    }
}

extension ContactPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return dataSource[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
