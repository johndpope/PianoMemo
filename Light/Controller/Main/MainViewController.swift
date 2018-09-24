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
    weak var persistentContainer: NSPersistentContainer!
    weak var noteEditable: NoteEditable?
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
        setDelegate()
        registerCell(NoteCell.self)
        loadNotes()
        checkIfNewUser()
        setNavigationbar()
        setupCloud()
    }
    
    private func setNavigationbar() {
        navigationController?.view.backgroundColor = UIColor.white
        setEditBtn()
        setSettingBtn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateItemSize), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        registerKeyboardNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        noteEditable?.note = nil
        noteEditable = nil

        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterKeyboardNotification()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            let kbHeight = bottomView.keyboardHeight ?? 300
            des.kbHeight = kbHeight < 200 ? 300 : kbHeight + 90
            self.noteEditable = des
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? ConnectViewController,
            let notRegisteredData = sender as? NotRegisteredData {
            vc.notRegisteredData = notRegisteredData
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
                cell.data = resultsController.object(at: indexPath)
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                guard let cell = collectionView.cellForItem(at: newIndexPath) as? NoteCell else { return }
                cell.data = resultsController.object(at: newIndexPath)
                
            }

            if let newNote = anObject as? Note,
                let noteEditable = noteEditable,
                let editingNote = noteEditable.note,
                newNote == editingNote {

                noteEditable.note = newNote
            }
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
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return Preference.lineSpacing
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        lineFragmentUsedRect.pointee.size.height -= Preference.lineSpacing
        return true
    }
}
