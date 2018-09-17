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
    var mainContext: NSManagedObjectContext!
    private let eventStore = EKEventStore()
    var identifiersToDelete: [String] = []
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            collectionView.reloadData()
            selectCollectionViewForConnectedReminder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerHeaderView(PianoCollectionReusableView.self)
        registerCell(ReminderViewModelCell.self)
        collectionView?.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        Access.eventRequest(from: self) {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.appendRemindersToDataSource()
            }
        }
    }
}

extension ReminderPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        
        let identifiersToAdd = collectionView?.indexPathsForSelectedItems?.compactMap({ (indexPath) -> String? in
            return (dataSource[indexPath.section][indexPath.item] as? ReminderViewModel)?.reminder.calendarItemExternalIdentifier
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
            self.mainContext.performAndWait {
                self.mainContext.saveIfNeeded()
            }
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
                    guard let reminderViewModel = collectionData as? ReminderViewModel else { return }
                    if self.note.reminderIdentifiers.contains(reminderViewModel
                        .reminder
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
    
    
    
    private func appendRemindersToDataSource() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate) {[weak self] (reminders) in
            guard let reminderViewModels = reminders?.map({ (reminder) -> ReminderViewModel in
                return ReminderViewModel(reminder: reminder, sectionTitle: "Reminder", sectionImage: #imageLiteral(resourceName: "suggestionsReminder"), sectionIdentifier: PianoCollectionReusableView.reuseIdentifier)
            }) else {return }
            
            self?.dataSource.append(reminderViewModels)
        }
    }
}

extension ReminderPickerCollectionViewController {
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

extension ReminderPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? ReminderViewModel else { return }
        
        if let index = identifiersToDelete.index(of: viewModel.reminder.calendarItemExternalIdentifier) {
            identifiersToDelete.remove(at: index)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
        guard let viewModel = dataSource[indexPath.section][indexPath.item] as? ReminderViewModel,
            let identifier = viewModel.reminder.calendarItemExternalIdentifier else { return }
        
        if note.reminderIdentifiers.contains(identifier) {
            identifiersToDelete.append(identifier)
        }
    }
}

extension ReminderPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
