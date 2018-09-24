//
//  EventPickerCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 11..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI
import CoreData


class EventPickerCollectionViewController: UICollectionViewController, NoteEditable, CollectionRegisterable {

    var note: Note!
    let eventStore = EKEventStore()
    var identifiersToDelete: [String] = []
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.collectionView.reloadData()
                self.selectCollectionViewForConnectedEvent()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        registerHeaderView(PianoReusableView.self)
        registerCell(EKEventCell.self)
        Access.eventRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            self.appendEventsToDataSource()
        }
    }
}

extension EventPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        let identifiersToAdd = collectionView?.indexPathsForSelectedItems?.compactMap({ (indexPath) -> String? in
            return (dataSource[indexPath.section][indexPath.item] as? EKEvent)?.calendarItemExternalIdentifier
        })
        
        guard let privateContext = note.managedObjectContext else { return }
        
        privateContext.perform { [ weak self ] in
            guard let `self` = self else { return }
            
            if let identifiersToAdd = identifiersToAdd {
                identifiersToAdd.forEach { identifier in
                    if !self.note.eventIdentifiers.contains(identifier) {
                        let event = Event(context: privateContext)
                        event.identifier = identifier
                        event.addToNoteCollection(self.note)
                    }
                }
            }
            
            self.identifiersToDelete.forEach { identifier in
                guard let event = self.note.eventCollection?.filter({ (value) -> Bool in
                    guard let event = value as? Event,
                        let existIdentifier = event.identifier else { return false }
                    return identifier == existIdentifier
                }).first as? Event else { return }
                privateContext.delete(event)
            }
            
            privateContext.saveIfNeeded()
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension EventPickerCollectionViewController {
    private func selectCollectionViewForConnectedEvent(){
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            
            self.dataSource.enumerated().forEach({ (section, collectionDatas) in
                collectionDatas.enumerated().forEach({ (item, collectionData) in
                    guard let ekEvent = collectionData as? EKEvent else { return }
                    if self.note.eventIdentifiers.contains(ekEvent.calendarItemExternalIdentifier) {
                        let indexPath = IndexPath(item: item, section: section)
                        DispatchQueue.main.async {
                            self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
                        }
                    }
                })
            })
            
        }
    }
    
    private func appendEventsToDataSource() {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let cal = Calendar.current
            guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
            let predicate = self.eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: nil)
            let ekEvents = self.eventStore.events(matching: predicate)
            self.dataSource.append(ekEvents)
        }
    }
}

extension EventPickerCollectionViewController {
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
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
            reusableView.data = dataSource[indexPath.section][indexPath.item]
            return reusableView
        }
    
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            return dataSource[section].first?.headerSize ?? CGSize.zero
        }
}

extension EventPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let ekEvent = dataSource[indexPath.section][indexPath.item] as? EKEvent else { return }
        if let index = identifiersToDelete.index(of: ekEvent.calendarItemExternalIdentifier) {
            identifiersToDelete.remove(at: index)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let ekEvent = dataSource[indexPath.section][indexPath.item] as? EKEvent,
            let identifier = ekEvent.calendarItemExternalIdentifier else { return }
        
        if note.eventIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension EventPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
