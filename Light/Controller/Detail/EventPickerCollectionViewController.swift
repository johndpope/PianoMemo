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


class EventPickerCollectionViewController: UICollectionViewController, NoteEditable {

    var note: Note!
    
    let eventStore = EKEventStore()
    
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView?.reloadData()
                self?.selectCollectionViewForConnectedEvent()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.allowsMultipleSelection = true
        
        appendEventsToDataSource()
    }

}

extension EventPickerCollectionViewController {
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        //selectedIndexPath를 돌아서 뷰 모델을 추출해내고, 노트의 기존 reminder의 identifier와 비교해서 다르다면 노트에 삽입해주기
        
        collectionView?.indexPathsForSelectedItems?.forEach({ (indexPath) in
            guard let calendarItemExternalIdentifier = ((collectionView?.cellForItem(at: indexPath) as? EventViewModelCell)?.data as? EventViewModel)?.event.calendarItemExternalIdentifier else { return }
            
            if !note.eventIdentifiers.contains(calendarItemExternalIdentifier) {
                guard let context = note.managedObjectContext else { return }
                let event = Event(context: context)
                event.identifier = calendarItemExternalIdentifier
                event.addToNoteCollection(note)
            }
        })
        
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
                            self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                        }
                    }
                })
            })
            
        }
    }
    
    private func appendEventsToDataSource() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            eventStore.requestAccess(to: .reminder) { [weak self] (status, error) in
                switch status {
                case true: self?.fetchEvents()
                case false: self?.alert()
                }
            }
            
        case .authorized: fetchEvents()
        case .restricted, .denied: alert()
        }
    }
    
    private func fetchEvents() {
        let cal = Calendar.current
        guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
        let predicate = eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: nil)
        let eventViewModels = eventStore.events(matching: predicate).map { (ekEvent) -> EventViewModel in
            return EventViewModel(event: ekEvent, infoAction: { [weak self] in
                let eventVC = EKEventViewController()
                eventVC.allowsEditing = false
                eventVC.event = ekEvent
                eventVC.allowsEditing = true
                self?.navigationController?.pushViewController(eventVC, animated: true)
            })
        }
        
        dataSource.append(eventViewModels)
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
    
    //    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    //        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? "DetailIVCollectionReusableView", for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
    //        reusableView.data = dataSource[indexPath.section][indexPath.item]
    //        return reusableView
    //    }
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    //        return dataSource[section].first?.headerSize ?? CGSize.zero
    //    }
}

extension EventPickerCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
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
