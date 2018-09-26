//
//  TextInputView.swift
//  Piano
//
//  Created by Kevin Kim on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class TextInputView: UIView, CollectionRegisterable {
    enum DataType {
        case reminder
        case event
    }
    
    internal func setup(viewController: ViewController, textView: TextView) {
        self.parentViewController = viewController
        self.textView = textView
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        registerHeaderView(PianoReusableView.self)
        registerCell(EKEventCell.self)
        registerCell(EKReminderCell.self)
    }
    
    @IBOutlet weak var collectionView: CollectionView!
    weak private var parentViewController: UIViewController?
    weak private var textView: TextView?
    
    internal var dataType = DataType.event {
        didSet {
            
            guard let vc = parentViewController else { return }
            collectionDatables = []
            switch dataType {
            case .event:
                Access.eventRequest(from: vc) { [weak self] in
                    guard let `self` = self else { return }
                    self.appendEventsToDataSource()
                }
            case .reminder:
                Access.eventRequest(from: vc) { [weak self] in
                    guard let `self` = self else { return }
                    self.appendRemindersToDataSource()
                }
            }
        }
    }
    
    private let eventStore = EKEventStore()
    private var collectionDatables: [[CollectionDatable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
    
}

extension TextInputView {
    
    private func appendEventsToDataSource() {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let cal = Calendar.current
            guard let endDate = cal.date(byAdding: .year, value: 1, to: cal.today) else {return}
            let predicate = self.eventStore.predicateForEvents(withStart: cal.today, end: endDate, calendars: nil)
            let ekEvents = self.eventStore.events(matching: predicate)
            self.collectionDatables.append(ekEvents)
        }
    }
    
    private func appendRemindersToDataSource() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate
            , completion: {
                guard let reminders = $0 else { return }
                self.collectionDatables.append(reminders)
        })
    }
}

extension TextInputView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = collectionDatables[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
        cell.data = data
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionDatables[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionDatables.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: collectionDatables[indexPath.section][indexPath.item].reusableViewReuseIdentifier, for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = collectionDatables[indexPath.section][indexPath.item]
        return reusableView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return collectionDatables[section].first?.headerSize ?? CGSize.zero
    }
}

extension TextInputView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let reminder = collectionDatables[indexPath.section][indexPath.item] as? EKReminder {
            var str = ": "
            if let title = reminder.title {
                str.append(title + " ")
            }
            if let date = reminder.alarmDate {
                str.append(DateFormatter.longSharedInstance.string(from: date))
            }
            
            textView?.insertText(str)
            textView?.insertText("\n")
            
        } else if let event = collectionDatables[indexPath.section][indexPath.item] as? EKEvent {
            var str = "🗓 "
            if let title = event.title {
                str.append(title + " ")
            }
            
            if let startDate = event.startDate {
                str.append(DateFormatter.longSharedInstance.string(from: startDate))
            }
            
            if let endDate = event.endDate {
                str.append(" ~ " + DateFormatter.longSharedInstance.string(from: endDate))
            }
            
            textView?.insertText(str)
            textView?.insertText("\n")
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
}

extension TextInputView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionDatables[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionDatables[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionDatables[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionDatables[section].first?.minimumInteritemSpacing ?? 0
    }
    
}
