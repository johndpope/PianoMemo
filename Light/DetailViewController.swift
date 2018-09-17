//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos
import CoreData
import EventKitUI
import ContactsUI
import CloudKit

enum DataType: Int {
    case reminder = 0
    case calendar = 1
    case photo = 2
    case mail = 3
    case contact = 4
}

protocol NoteEditable {
    var note: Note! { get set }
}

class DetailViewController: UIViewController, NoteEditable {
    
    
    var note: Note!
    weak var persistentContainer: NSPersistentContainer!
    @IBOutlet weak var fakeTextField: UITextField!
    @IBOutlet var detailInputView: DetailInputView!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var completionToolbar: UIToolbar!
    @IBOutlet weak var shareItem: UIBarButtonItem!
    
    var kbHeight: CGFloat = 300
    var delayCounter = 0
    var oldContent = ""
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
        request.predicate = NSPredicate(format: "recordName == %@", note.recordName ?? "")
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTextView()
        setTextField()
        setDelegate()
        setNavigationBar(state: .normal)
        setShareImage()
        setResultsController()
        discoverUserIdentity()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotification()
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unRegisterKeyboardNotification()
        saveNoteIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let navVC = segue.destination as? UINavigationController,
            var vc = navVC.topViewController as? NoteEditable {
            vc.note = note
            return
        }
        
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.topViewController as? PhotoDetailViewController,
            let asset = sender as? PHAsset {
            vc.asset = asset
            return
        }
        
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.topViewController as? MailDetailViewController,
            let html = sender as? String {
            vc.html = html
            return
        }
        
        if let vc = segue.destination as? PhotoDetailViewController,
            let asset = sender as? PHAsset {
            vc.asset = asset
            return
        }
        
        if let vc = segue.destination as? EventDetailViewController,
            let ekEvent = sender as? EKEvent {
            vc.event = ekEvent
            vc.allowsEditing = true
            return
        }
        
    }
    
    
    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(){
        guard let context = note.managedObjectContext, textView.hasEdit else { return }
        
        context.performAndWait {
            var ranges: [NSRange] = []
            textView.attributedText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, textView.attributedText.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
                guard let backgroundColor = value as? Color, backgroundColor == Color.highlight else { return }
                ranges.append(range)
            }
            
            note.atttributes = NoteAttributes(highlightRanges: ranges)
            cloudManager?.upload.oldContent = note.content ?? ""
            note.content = textView.text
            textView.hasEdit = false
            context.saveIfNeeded()
        }
        
    }
    
}

extension DetailViewController {
    private func setTextField() {
        fakeTextField.inputView = detailInputView
    }
    
    private func setDelegate() {
        textView.layoutManager.delegate = self
        detailInputView.detailVC = self
    }
    
    private func setTextView() {
        
        if let text = note.content {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let mutableAttrString = text.createFormatAttrString()
                
                if let noteAttribute = self?.note.atttributes {
                    noteAttribute.highlightRanges.forEach {
                        mutableAttrString.addAttributes([.backgroundColor : Color.highlight], range: $0)
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.textView.attributedText = mutableAttrString
                    self?.textView.selectedRange.location = 0
                }
            }
        }
        
        if let date = note.modifiedDate {
            let string = DateFormatter.sharedInstance.string(from:date)
            self.textView.setDescriptionLabel(text: string)
        }
        
        textView.contentInset.bottom = bottomHeight
        textView.scrollIndicatorInsets.bottom = bottomHeight
    }
    
    enum VCState {
        case normal
        case typing
        case piano
    }
    
    internal func setNavigationBar(state: VCState){
        var btns: [BarButtonItem] = []
        
        switch state {
        case .normal:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        case .piano:
            
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                navigationItem.titleView = titleView
            }
            
            let leftBtns = [BarButtonItem(title: "", style: .plain, target: nil, action: nil)]
            
            navigationItem.setLeftBarButtonItems(leftBtns, animated: true)
        }
        
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
    internal func setToolBar(state: VCState) {
        completionToolbar.isHidden = state != .piano
    }
    
    internal func setShareImage() {
        if note.record()?.share != nil {
            shareItem.image = UIImage(named: "info")
        } else {
            shareItem.image = UIImage(named: "share")
        }
    }
    
    private func setResultsController() {
        oldContent = note.content ?? ""
        resultsController.delegate = self
        try? resultsController.performFetch()
    }
    
    private func discoverUserIdentity() {
        guard note.record()?.share != nil else {return}
        guard let userID = cloudManager?.accountChanged?.userID else {return}
        guard let lastUserID = note.record()?.lastModifiedUserRecordID else {return}
        guard userID != lastUserID else {return}
        CKContainer.default().discoverUserIdentity(withUserRecordID: lastUserID) { (id, error) in
            if let nameComponent = id?.nameComponents {
                let name = (nameComponent.givenName ?? "") + (nameComponent.familyName ?? "")
                if let date = self.note.modifiedDate, !name.isEmpty {
                    let string = DateFormatter.sharedInstance.string(from:date)
                    self.textView.setDescriptionLabel(text: string + " \(name)님이 마지막으로 수정했습니다.")
                }
            }
        }
    }
    
}

extension DetailViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
    }
    
}

