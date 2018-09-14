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
    let newUserKey = "Key_New_User"
    
    var textViewHasEdit: Bool = false
    
    
    @IBOutlet weak var noResultsView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: BottomView!
    @IBOutlet weak var indicatorTableView: IndicatorTableView!
    @IBOutlet weak var indicatorTableViewHeightConstraint: NSLayoutConstraint!
    weak var persistentContainer: NSPersistentContainer!
    var inputTextCache = [String]()

    lazy var mainContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return persistentContainer.newBackgroundContext()
    }()

    lazy var fetchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    lazy var indicateOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()

    lazy var resultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: "Note"
        )
        return controller
    }()

    lazy var blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .extraLight)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
        setupCollectionViewLayout()
        loadNotes()
        setupBlurView()
        checkIfNewUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotification()
        
        if textViewHasEdit {
            loadNotes()
            textViewHasEdit = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterKeyboardNotification()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.mainContext = mainContext
            let kbHeight = bottomView.keyboardHeight ?? 300
            des.kbHeight = kbHeight < 200 ? 300 : kbHeight
            des.mainViewController = self
        }
    }
}

extension MainViewController {
    
    func loadNotes() {
        requestQuery("")
    }
    
    private func setDelegate(){
        bottomView.mainViewController = self
    }
    
    internal func setupCollectionViewLayout() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        //        414보다 크다면, (뷰 가로길이 - (3 + 1) * 8) / 3 이 320보다 크다면 이 값으로 가로길이 정한다. 작다면
        //        (뷰 가로길이 - (2 + 1) * 8) / 2 이 320보다 크다면 이 값으로 가로길이를 정한다. 작다면
        //        뷰 가로길이 - (1 + 1) * 8 / 2 로 가로 길이를 정한다.
        if view.bounds.width > 414 {
          
            let widthOne = (view.bounds.width - (3 + 1) * 8) / 3
            if widthOne > 320 {
                flowLayout.itemSize = CGSize(width: widthOne, height: 100)
                flowLayout.minimumInteritemSpacing = 8
                flowLayout.minimumLineSpacing = 8
                flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                return
            }
            
            let widthTwo = (view.bounds.width - (2 + 1) * 8) / 2
            if widthTwo > 320 {
                flowLayout.itemSize = CGSize(width: widthTwo, height: 100)
                flowLayout.minimumInteritemSpacing = 8
                flowLayout.minimumLineSpacing = 8
                flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                return
            }
        }
            
            
            flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width - 16, height: 100)
            flowLayout.minimumInteritemSpacing = 8
            flowLayout.minimumLineSpacing = 8
            flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            return
        
    }

    private func setupBlurView() {
        view.insertSubview(blurView, aboveSubview: noResultsView)
        let constraints: [NSLayoutConstraint] = [
            blurView.widthAnchor.constraint(equalTo: collectionView.widthAnchor),
            blurView.heightAnchor.constraint(equalTo: collectionView.heightAnchor),
            blurView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            blurView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func checkIfNewUser() {
        if !UserDefaults.standard.bool(forKey: newUserKey) {
            performSegue(withIdentifier: <#T##String#>, sender: <#T##Any?#>)
        }
    }
}

