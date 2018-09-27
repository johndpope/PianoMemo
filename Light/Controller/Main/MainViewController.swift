//
//  MainViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class MainViewController: UIViewController, CollectionRegisterable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: BottomView!
    @IBOutlet weak var textAccessoryView: UIView!
    @IBOutlet var textInputView: TextInputView!
    internal var kbHeight: CGFloat = 300
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    @IBOutlet weak var bottomStackViewTrailingAnchor: NSLayoutConstraint!
    @IBOutlet weak var bottomStackViewLeadingAnchor: NSLayoutConstraint!
    weak var syncService: SynchronizeServiceType!
//    weak var noteEditable: NoteEditable?
    var inputTextCache = [String]()

    lazy var recommandOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
        registerCell(NoteCell.self)
        loadNotes()
        checkIfNewUser()
        setNavigationbar()
        setupCloud()
        
        textInputView.setup(viewController: self, textView: bottomView.textView)
    }
    
    private func setNavigationbar() {
        navigationController?.view.backgroundColor = UIColor.white
        setEditBtn()
        setSettingBtn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterKeyboardNotification()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self](context) in
            guard let `self` = self else { return }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.bottomStackViewLeadingAnchor.constant = self.view.marginLeft
            self.bottomStackViewTrailingAnchor.constant = self.view.marginRight
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            return
        }
    }
}

extension MainViewController {
    
    func loadNotes() {
        requestQuery("")
    }
    
}

extension MainViewController {
    
    @objc private func updateItemSize() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setDelegate(){
        bottomView.mainViewController = self
        bottomView.textView.layoutManager.delegate = self
        bottomView.recommandEventView.mainViewController = self
        bottomView.recommandContactView.mainViewController = self
        bottomView.recommandReminderView.mainViewController = self
    }

    // TODO: 이런 건 다 syncservice 에서 해줘야 함.
    private func checkIfNewUser() {
//        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExistingUserKey) {
//            performSegue(withIdentifier: ChecklistPickerViewController.identifier, sender: syncService.backgroundContext)
//        }
    }
    // TODO: 이런 건 다 syncservice 에서 해줘야 함.
    private func setupCloud() {
//        cloudManager?.download.backgroundContext = backgroundContext
//        cloudManager?.setup()
    }
    
}

extension MainViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let share = cloudManager?.share.targetShare {
            DispatchQueue.main.sync {
                guard let sharedNote = self.syncService.resultsController.fetchedObjects?.first(where: {
                    $0.record()?.share?.recordID == share.recordID}) else {return}
                self.performSegue(withIdentifier: DetailViewController.identifier, sender: sharedNote)
                cloudManager?.share.targetShare = nil
                self.bottomView.textView.resignFirstResponder()
            }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        func update() {
            switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else {return}
                collectionView.insertItems(at: [newIndexPath])
            case .delete:
                guard let indexPath = indexPath else {return}
                collectionView.deleteItems(at: [indexPath])
            case .update:
                guard let indexPath = indexPath,
                    let cell = collectionView.cellForItem(at: indexPath) as? NoteCell else {return}
                cell.data = syncService.resultsController.object(at: indexPath)
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                guard let cell = collectionView.cellForItem(at: newIndexPath) as? NoteCell else { return }
                cell.data = syncService.resultsController.object(at: newIndexPath)
                
            }
            

//            if let newNote = anObject as? Note,
//                let noteEditable = noteEditable,
//                let editingNote = noteEditable.note,
//                newNote == editingNote {
//
//                noteEditable.note = newNote
//            }
        }
        
//        if !Thread.isMainThread {
//            DispatchQueue.main.sync {
//                update()
//            }
//        } else {
//            update()
//        }
    }
    
}

extension MainViewController: NSLayoutManagerDelegate {
//    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
//        return Preference.lineSpacing
//    }
//    
//    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
//        lineFragmentUsedRect.pointee.size.height -= Preference.lineSpacing
//        return true
//    }
}
