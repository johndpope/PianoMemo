//
//  NoteCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

class NoteCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewContext: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
    lazy var privateQueue: OperationQueue = {
       return OperationQueue()
    }()
    
    lazy var resultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(fetchRequest: Note.masterRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: "Note")
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if viewContext == nil,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.viewContext = appDelegate.syncCoordinator.viewContext
            self.backgroundContext = appDelegate.syncCoordinator.backgroundContext
        } else {
            setup()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotifications()
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        self.setup()
        super.decodeRestorableState(with: coder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deleteSelectedNoteWhenEmpty()
        EditingTracker.shared.setEditingNote(note: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SettingTableViewController {
            vc.dataService = self
            return
        }
        
        if let des = segue.destination as? DetailViewController {
            des.writeService = self
            des.note = sender as? Note
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SearchViewController {
            vc.dataService = self
            return
        }
    }
    

}

extension NoteCollectionViewController {
    private func setup() {
        resultsController.delegate = self
        //TODO: 마이그레이션 코드 넣어야 함.
        
        
        if !UserDefaults.didContentMigration() {
            let bulk = BulkUpdateOperation(request: Note.allfetchRequest(), context: viewContext) { [weak self] in
                guard let self = self else { return }
                self.loadData()
                UserDefaults.doneContentMigration()
            }
            privateQueue.addOperation(bulk)
        } else {
            self.loadData()
        }
        
        //TODO: collectionView의 bottomInset값 세팅하기
    }
    
    private func loadData() {
        //TODO: resultsController perform 시키고, reloadData
    }
    
    private func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
    }
    
    @objc func pasteboardChanged() {
        
    }
    
    private func unRegisterAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func deleteSelectedNoteWhenEmpty() {
        collectionView.visibleCells.forEach {
            guard let indexPath = collectionView.indexPath(for: $0) else { return }
            collectionView.deselectItem(at: indexPath, animated: true)
            let note = resultsController.object(at: indexPath)
            if note.content?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                purge(notes: [note])
            }
        }
    }
}

extension NoteCollectionViewController: Writable, Readable {}
