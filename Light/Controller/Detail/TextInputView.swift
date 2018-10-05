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
    
    @IBOutlet weak var collectionView: CollectionView!
    weak private var parentViewController: UIViewController?
    weak private var textView: TextView?
    
    internal var dataType = DataType.event {
        didSet {
            
            guard let vc = parentViewController else { return }
            switch dataType {
            case .event:
                Access.eventRequest(from: vc) { [weak self] in
                    guard let `self` = self else { return }
                    self.appendEventsToCollectionables()
                }
            case .reminder:
                Access.reminderRequest(from: vc) { [weak self] in
                    guard let `self` = self else { return }
                    self.appendRemindersToCollectionables()
                }
            }
        }
    }
    
    internal func setup(viewController: ViewController, textView: TextView) {
        self.parentViewController = viewController
        self.textView = textView
        registerCell(EKEventCell.self)
        registerCell(EKReminderCell.self)
    }
    func showEmptyStateViewIfNeeded(){
        guard collectionables.first?.count == 0 else {
            EmptyStateView.detach(on: self)
            return
        }
        let message = dataType != .event
            ? "Register Reminders.\n: Business meeting at 3 pm with Sasha\n(You should type ‘:’ and spacing before you write dates to do!)".loc
            : "일정을 등록해보세요.\n예시)\n오후 세시 케빈과 미팅".loc
        EmptyStateView.attach(on: self, message: message)
    }
    
    private let eventStore = EKEventStore()
    private var collectionables: [[Collectionable]] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.showEmptyStateViewIfNeeded()
                self.collectionView.reloadData()
            }
        }
    }
}

extension TextInputView {
    
    private func appendEventsToCollectionables() {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let cal = Calendar.current
            guard let endDate = cal.date(byAdding: .year, value: 1, to: Date()) else {return}
            let predicate = self.eventStore.predicateForEvents(withStart: Date(), end: endDate, calendars: nil)
            let ekEvents = self.eventStore.events(matching: predicate)
            self.collectionables = [ekEvents]
        }
    }
    
    private func appendRemindersToCollectionables() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate
            , completion: {
                guard let ekReminders = $0 else { return }
                self.collectionables = [ekReminders]
        })
    }
}

extension TextInputView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let collectionable = collectionables[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionable.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        switch dataType {
        case .event:
            let event = collectionable as! EKEvent
            let viewModel = EventViewModel(ekEvent: event)
            cell.viewModel = viewModel
        case .reminder:
            let reminder = collectionable as! EKReminder
            let viewModel = ReminderViewModel(ekReminder: reminder)
            cell.viewModel = viewModel
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionables[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionables.count
    }
    
}

extension TextInputView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let reminder = collectionables[indexPath.section][indexPath.item] as? EKReminder {
            var str = ": "
            if let title = reminder.title {
                str.append(title + " ")
            }
            if let date = reminder.alarmDate {
                str.append(DateFormatter.longSharedInstance.string(from: date))
            }
            
            textView?.insertText(str)
            textView?.insertText("\n")
            
        } else if let event = collectionables[indexPath.section][indexPath.item] as? EKEvent {
            var str = ""
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
        
        textView?.inputView = nil
        textView?.reloadInputViews()
        if let mainVC = parentViewController as? MainViewController,
            let selectedItems = mainVC.textAccessoryVC?.collectionView.indexPathsForSelectedItems {
            selectedItems.forEach {
                mainVC.textAccessoryVC?.collectionView.deselectItem(at: $0, animated: true)
            }
        } else if let detailVC = parentViewController as? DetailViewController,
            let selectedItems = detailVC.textAccessoryVC?.collectionView.indexPathsForSelectedItems {
            selectedItems.forEach {
                detailVC.textAccessoryVC?.collectionView.deselectItem(at: $0, animated: true)
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
}

extension TextInputView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionables.first?.first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionables[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables.first?.first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables.first?.first?.minimumInteritemSpacing ?? 0
    }
    
}
