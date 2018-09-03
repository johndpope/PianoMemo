//
//  MainViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController {
    
    
    @IBOutlet weak var noResultsView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: BottomView!
    weak var persistentContainer: NSPersistentContainer!
    
    lazy var mainContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()
    
    var resultsController: NSFetchedResultsController<Note>?
    internal var typingCounter = 0
    internal var searchRequestDelay = 0.1
    
    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
        setupCollectionViewLayout()
        setSearchRequestDelay()
        loadNote()
//        setupDummyNotes()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterKeyboardNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [weak self] in
            self?.bottomView.textView.becomeFirstResponder()
        }
        
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            let kbHeight = bottomView.keyboardHeight ?? 300
            des.kbHeight = kbHeight < 200 ? 300 : kbHeight
        }
    }

}

extension MainViewController {
    
    private func loadNote() {
        resultsController = createNoteResultsController()
        do {
            try resultsController?.performFetch()
        } catch {
            print("loadNote에러: \(error.localizedDescription)")
        }
        
        noResultsView.isHidden = resultsController?.fetchedObjects?.count != 0
        collectionView.reloadData()
        
    }
    
    private func setDelegate(){
        bottomView.mainViewController = self
    }
    
    internal func createNoteResultsController() -> NSFetchedResultsController<Note> {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: "Note"
        )
        return controller
    }
    
    func refreshCollectionView() {
        do {
            
            guard let resultsController = resultsController,
                let old = resultsController.fetchedObjects else { return }
            
            try resultsController.performFetch()

            guard let new = resultsController.fetchedObjects, new != old else { return }

            let count = resultsController.fetchedObjects?.count ?? 0

            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.title = (count <= 0) ? "메모없음" : "\(count)개의 메모"
                self.noResultsView.isHidden = count != 0
                print("검색결과는 \(count) 개 입니다")
                self.collectionView.performBatchUpdates({
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }, completion: nil)
            }

        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")

        }
    }
    
    /// appDelegate applicationWillResignActive 에서 저장한 노트수에 따라서
    /// 검색 요청 지연 시간을 설정하는 메서드
    private func setSearchRequestDelay() {
        let noteCount = UserDefaults.standard.integer(forKey: "NoteCount")
        switch noteCount {
        case 0..<500:
            searchRequestDelay = 0.1
        case 500..<1000:
            searchRequestDelay = 0.2
        case 1000..<5000:
            searchRequestDelay = 0.3
        case 5000..<10000:
            searchRequestDelay = 0.4
        default:
            searchRequestDelay = 0.5
        }
    }
    
    internal func setupCollectionViewLayout() {
        //TODO: 임시로 해놓은 것이며 세팅해놓아야함
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 122)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
    }
}