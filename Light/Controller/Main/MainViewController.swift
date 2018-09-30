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
    
    var selectedNote: Note?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: BottomView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var textAccessoryView: UIView!
    @IBOutlet var accessoryButtons: [UIButton]!
    @IBOutlet var textInputView: TextInputView!
    internal var kbHeight: CGFloat = 300
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    @IBOutlet weak var bottomStackViewTrailingAnchor: NSLayoutConstraint!
    @IBOutlet weak var bottomStackViewLeadingAnchor: NSLayoutConstraint!
    let locationManager = CLLocationManager()
    
    weak var persistentContainer: NSPersistentContainer!
    var inputTextCache = [String]()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    lazy var fetchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var recommandOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.predicate = NSPredicate(format: "isInTrash == false")
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()
    
    lazy var resultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupDummyNotes()
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
        registerAllNotification()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
        
        if let note = selectedNote, note.content?.count == 0 {
            backgroundContext.performAndWait {
                backgroundContext.delete(note)
                backgroundContext.saveIfNeeded()
            }
        }
        selectedNote = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
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
        bottomView.recommandAddressView.mainViewController = self
    }
    
    private func checkIfNewUser() {
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExistingUserKey) {
            performSegue(withIdentifier: ChecklistPickerViewController.identifier, sender: backgroundContext)
        }
    }
    
    private func setupCloud() {
        cloudManager?.download.backgroundContext = backgroundContext
        cloudManager?.setup()
    }
    
}

extension MainViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let share = cloudManager?.share.targetShare {
            DispatchQueue.main.sync {
                guard let sharedNote = self.resultsController.fetchedObjects?.first(where: {
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
                let note = resultsController.object(at: indexPath)
                let viewModel = NoteViewModel(note: note, originNoteForMerge: nil)
                cell.viewModel = viewModel
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                guard let cell = collectionView.cellForItem(at: newIndexPath) as? NoteCell else { return }
                let note = resultsController.object(at: newIndexPath)
                let viewModel = NoteViewModel(note: note, originNoteForMerge: nil)
                cell.viewModel = viewModel
                
            }

//            if let newNote = anObject as? Note,
//                let noteEditable = noteEditable,
//                let editingNote = noteEditable.note,
//                newNote == editingNote {
//
//                noteEditable.note = newNote
//            }
        }
        
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                update()
            }
        } else {
            update()
        }
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
