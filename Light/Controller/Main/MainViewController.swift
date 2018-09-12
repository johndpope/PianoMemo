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
    
    var textViewHasEdit: Bool = false
    
    
    @IBOutlet weak var noResultsView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: BottomView!
    @IBOutlet weak var indicatorTableView: IndicatorTableView!
    @IBOutlet weak var indicatorTableViewHeightConstraint: NSLayoutConstraint!
    weak var persistentContainer: NSPersistentContainer!
    var inputTextCache = [String]()

//    lazy var mainContext: NSManagedObjectContext = {
//        let context = persistentContainer.viewContext
//        context.automaticallyMergesChangesFromParent = true
//        return context
//    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
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
        //TODO: 임시로 해놓은 것이며 세팅해놓아야함
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 122)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
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
}

