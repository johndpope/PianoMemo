//
//  MainViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

//더이상 안쓰는 컨트롤러
//import UIKit
//import CoreData
//import CloudKit
//import DifferenceKit
//import LocalAuthentication
//
//class MainViewController: UIViewController, CollectionRegisterable, InputViewChangeable {
//
//    var selectedNote: Note?
//    @IBOutlet weak var collectionView: UICollectionView!
//    @IBOutlet weak var bottomView: BottomView!
//    @IBOutlet var textInputView: TextInputView!
//    var readOnlyTextView: TextView { return bottomView.textView }
//
//    var textAccessoryVC: TextAccessoryViewController? {
//        for vc in children {
//            guard let textAccessoryVC = vc as? TextAccessoryViewController else { continue }
//            return textAccessoryVC
//        }
//        return nil
//    }
//
//    lazy var recommandOperationQueue: OperationQueue = {
//        let queue = OperationQueue()
//        queue.maxConcurrentOperationCount = 1
//        return queue
//    }()
//
//    internal var kbHeight: CGFloat = 300
//    weak var syncController: Synchronizable!
//    internal var notes = [NoteWrapper]()
//    internal var inputTextCache = ""
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setDelegate()
//        initialContentInset()
//        registerCell(NoteCell.self)
//        loadNotes()
//        textInputView.setup(viewController: self, textView: bottomView.textView)
//        syncController.setMainUIRefreshDelegate(self)
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        registerAllNotification()
//
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        DispatchQueue.main.async { [weak self] in
//            self?.checkIfNewUser()
//        }
//
//
//        collectionView.indexPathsForSelectedItems?.forEach {
//            collectionView.deselectItem(at: $0, animated: true)
//        }
//
//        if let note = selectedNote, note.content?.count == 0 {
//            syncController.purge(note: note) { [weak self] in
//                self?.selectedNote = nil
//            }
//        }
//        selectedNote = nil
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        unRegisterAllNotification()
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        if let des = segue.destination as? TextAccessoryViewController {
//            des.setup(textView: bottomView.textView, viewController: self)
//            return
//        }
//
//        if let des = segue.destination as? DetailViewController,
//            let note = sender as? Note {
//            des.note = note
//            //TODO COCOA:
////            des.syncController = self.syncController
//            return
//        }
//
//        if let des = segue.destination as? UINavigationController,
//            let vc = des.topViewController as? TrashCollectionViewController {
//            vc.syncController = self.syncController
//            return
//        }
//
//    }
//
////    internal func noteViewModel(indexPath: IndexPath) -> NoteViewModel {
////        let note = resultsController.object(at: indexPath)
////        return NoteViewModel(note: note, viewController: self)
////    }
//
//    private func checkIfNewUser() {
//        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExistingUserKey) {
//            performSegue(withIdentifier: ChecklistPickerViewController.identifier, sender: nil)
//        }
//    }
//}
//
//extension MainViewController {
//    func loadNotes() {
//        requestQuery("")
//    }
//
//    private func setDelegate(){
//        bottomView.mainViewController = self
//        bottomView.recommandEventView.setup(viewController: self, textView: bottomView.textView)
//        bottomView.recommandAddressView.setup(viewController: self, textView: bottomView.textView)
//        bottomView.recommandContactView.setup(viewController: self, textView: bottomView.textView)
//        bottomView.recommandReminderView.setup(viewController: self, textView: bottomView.textView)
//    }
//}
//
//extension MainViewController: UIRefreshDelegate {
//    func refreshUI(with target: [NoteWrapper], animated: Bool, completion: @escaping () -> Void) {
//        let changeSet = StagedChangeset(source: notes, target: target)
//
//        DispatchQueue.main.async { [weak self] in
//            if animated {
//                self?.collectionView.reload(using: changeSet, interrupt: nil) { collection in
//                    self?.notes = collection
//                }
//                updatedPresentingNote()
//            } else {
//
//                self?.notes = target
//                self?.collectionView.reloadData()
//            }
//            completion()
//        }
//
//        func updatedPresentingNote() {
//            if let viewControllers = navigationController?.viewControllers,
//                viewControllers.count > 1,
//                let detailViewController = viewControllers.last as? DetailViewController,
//                let change = changeSet.first?.elementUpdated.first {
//
//                let updated = target[change.element]
//                if detailViewController.note == updated.note {
//                    detailViewController.synchronize()
//                }
//            }
//        }
//    }
//}

//extension MainViewController: NSLayoutManagerDelegate {
//    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
//        return Preference.lineSpacing
//    }
//    
//    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
//        lineFragmentUsedRect.pointee.size.height -= Preference.lineSpacing
//        return true
//    }
//}