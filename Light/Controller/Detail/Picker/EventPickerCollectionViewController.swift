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
    var mainContext: NSManagedObjectContext!
    let eventStore = EKEventStore()
    var identifiersToDelete: [String] = []
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            collectionView.reloadData()
            selectCollectionViewForConnectedEvent()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        registerHeaderView(PianoCollectionReusableView.self)
        registerCell(EventViewModelCell.self)
        Access.eventRequest(from: self) {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.appendEventsToDataSource()       
            }
        }
    }

}

extension EventPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        let identifiersToAdd = collectionView?.indexPathsForSelectedItems?.compactMap({ (indexPath) -> String? in
            return (dataSource[indexPath.section][indexPath.item] as? EventViewModel)?.event.calendarItemExternalIdentifier
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
            self.mainContext.performAndWait {
                self.mainContext.saveIfNeeded()
            }
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
                    guard let eventViewModel = collectionData as? EventViewModel else { return }
                    if self.note.eventIdentifiers.contains(eventViewModel
                        .event
                        .calendarItemExternalIdentifier) {
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
        let cal = Calendar.current
        guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
        let predicate = eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: nil)
        let eventViewModels = eventStore.events(matching: predicate).map { (ekEvent) -> EventViewModel in
            return EventViewModel(event: ekEvent, sectionTitle: "Calendar".loc, sectionImage: Image(imageLiteralResourceName: "suggestionsMail"), sectionIdentifier: PianoCollectionReusableView.reuseIdentifier)
        }
        
        dataSource.append(eventViewModels)
    }
}

extension EventPickerCollectionViewController {
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
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? PianoCollectionReusableView.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
            reusableView.data = dataSource[indexPath.section][indexPath.item]
            return reusableView
        }
    
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            return dataSource[section].first?.headerSize ?? CGSize.zero
        }
}

extension EventPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? EventViewModel else { return }
        
        if let index = identifiersToDelete.index(of: viewModel.event.calendarItemExternalIdentifier) {
            identifiersToDelete.remove(at: index)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
        
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? EventViewModel,
            let identifier = viewModel.event.calendarItemExternalIdentifier else { return }
        
        if note.eventIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension EventPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
