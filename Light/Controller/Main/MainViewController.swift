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
    var inputTextCache = [String]()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        return context
    }()
    
    lazy var fetchOperationQueue: OperationQueue = {
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
        registerCell(NoteCollectionViewCell.self)
        setupCollectionViewLayout()
        loadNotes()
        checkIfNewUser()
        setNavigationbar()
        setupCloud()
    }
    
    private func setNavigationbar() {
        navigationController?.view.backgroundColor = UIColor.white
        setEditBtn()
    }
    

    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateItemSize), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
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
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            let kbHeight = bottomView.keyboardHeight ?? 300
            des.kbHeight = kbHeight < 200 ? 300 : kbHeight + 90
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
        setupCollectionViewLayout()
        collectionView.reloadData()
    }
    
    private func setDelegate(){
        bottomView.mainViewController = self
    }
    
    private func setupCollectionViewLayout() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        //        414보다 크다면, (뷰 가로길이 - (3 + 1) * 8) / 3 이 320보다 크다면 이 값으로 가로길이 정한다. 작다면
        //        (뷰 가로길이 - (2 + 1) * 8) / 2 이 320보다 크다면 이 값으로 가로길이를 정한다. 작다면
        //        뷰 가로길이 - (1 + 1) * 8 / 2 로 가로 길이를 정한다.
        
        let titleHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .headline)]).size().height
        let bodyHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height * 2
        let margin: CGFloat = (4 * 2) + (8 * 2)
        let totalHeight = titleHeight + bodyHeight + margin
        if view.bounds.width > 414 {
            
            let widthOne = (view.bounds.width - (3 + 1) * 8) / 3
            if widthOne > 320 {
                flowLayout.itemSize = CGSize(width: widthOne, height: totalHeight)
                flowLayout.minimumInteritemSpacing = 8
                flowLayout.minimumLineSpacing = 8
                flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                return
            }
            
            let widthTwo = (view.bounds.width - (2 + 1) * 8) / 2
            if widthTwo > 320 {
                flowLayout.itemSize = CGSize(width: widthTwo, height: totalHeight)
                flowLayout.minimumInteritemSpacing = 8
                flowLayout.minimumLineSpacing = 8
                flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                return
            }
        }
        
        flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width - 16, height: totalHeight)
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 8
        flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return
        
    }
    
    private func checkIfNewUser() {
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExistingUserKey) {
            performSegue(withIdentifier: BeginingEmojiSelectionViewController.identifier, sender: nil)
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExistingUserKey)
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
                guard let indexPath = indexPath else {return}
                let cell = collectionView.cellForItem(at: indexPath) as! NoteCollectionViewCell
                configure(noteCell: cell, indexPath: indexPath)
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                let cell = collectionView.cellForItem(at: newIndexPath) as! NoteCollectionViewCell
                configure(noteCell: cell, indexPath: newIndexPath)
                
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

