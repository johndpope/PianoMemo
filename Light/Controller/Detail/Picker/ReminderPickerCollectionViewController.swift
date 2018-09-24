//
//  ReminderPickerCollectionViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 11..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI
import CoreData


class ReminderPickerCollectionViewController: UICollectionViewController, NoteEditable, CollectionRegisterable {
    
    var note: Note!
    private let eventStore = EKEventStore()
    var identifiersToDelete: [String] = []
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
                self?.selectCollectionViewForConnectedReminder()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerHeaderView(PianoReusableView.self)
        registerCell(EKReminderCell.self)
        collectionView?.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        Access.eventRequest(from: self) { [weak self] in
            self?.appendRemindersToDataSource()
        }
    }
}

extension ReminderPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        let identifiersToAdd = collectionView?.indexPathsForSelectedItems?.compactMap({ (indexPath) -> String? in
            return (dataSource[indexPath.section][indexPath.item] as? EKReminder)?.calendarItemExternalIdentifier
        })
        
        guard let privateContext = note.managedObjectContext else { return }
        
        privateContext.perform { [ weak self ] in
            guard let `self` = self else { return }
            
            if let identifiersToAdd = identifiersToAdd {
                identifiersToAdd.forEach { identifier in
                    if !self.note.reminderIdentifiers.contains(identifier) {
                        let reminder = Reminder(context: privateContext)
                        reminder.identifier = identifier
                        reminder.addToNoteCollection(self.note)
                    }
                }
            }
            
            self.identifiersToDelete.forEach { identifier in
                guard let reminder = self.note.reminderCollection?.filter({ (value) -> Bool in
                    guard let reminder = value as? Reminder,
                        let existIdentifier = reminder.identifier else { return false }
                    return identifier == existIdentifier
                }).first as? Reminder else { return }
                privateContext.delete(reminder)
            }
            
            privateContext.saveIfNeeded()
        }
        
        dismiss(animated: true, completion: nil)
        
    }
}

extension ReminderPickerCollectionViewController {
    private func selectCollectionViewForConnectedReminder(){
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            self.dataSource.enumerated().forEach({ (section, collectionDatas) in
                collectionDatas.enumerated().forEach({ (item, collectionData) in
                    guard let ekReminder = collectionData as? EKReminder else { return }
                    if self.note.reminderIdentifiers.contains(ekReminder.calendarItemExternalIdentifier) {
                        let indexPath = IndexPath(item: item, section: section)
                        DispatchQueue.main.async {
                            self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
                        }
                    }
                })
            })
            
        }
    }
    
    
    
    private func appendRemindersToDataSource() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate
            , completion: {
                guard let reminders = $0 else { return }
                self.dataSource.append(reminders)
        })
    }
}

extension ReminderPickerCollectionViewController {
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

extension ReminderPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let ekReminder = dataSource[indexPath.section][indexPath.item] as? EKReminder else { return }
        
        if let index = identifiersToDelete.index(of: ekReminder.calendarItemExternalIdentifier) {
            identifiersToDelete.remove(at: index)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let ekReminder = dataSource[indexPath.section][indexPath.item] as? EKReminder,
            let identifier = ekReminder.calendarItemExternalIdentifier else { return }
        
        if note.reminderIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension ReminderPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
