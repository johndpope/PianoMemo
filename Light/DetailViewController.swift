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
import Differ

enum DataType: Int {
    case reminder = 0
    case calendar = 1
    case photo = 2
    case mail = 3
    case contact = 4
}

protocol NoteEditable: class {
    var note: Note! { get set }
}

class DetailViewController: UIViewController, NoteEditable {
    
    
    var note: Note! {
        didSet {
            if oldValue != nil, note != nil {
                realtimeUpdate(with: note)
            }
        }
    }

    @IBOutlet weak var fakeTextField: UITextField!
    @IBOutlet var detailInputView: DetailInputView!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var completionToolbar: UIToolbar!
    @IBOutlet weak var shareItem: UIBarButtonItem!
    
    var kbHeight: CGFloat = 300
    var delayCounter = 0
    var oldContent = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTextView()
        setTextField()
        setDelegate()
        setNavigationBar(state: .normal)
        setShareImage()
        discoverUserIdentity()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotification()
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unRegisterKeyboardNotification()
        saveNoteIfNeeded(textView: textView)
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
    internal func saveNoteIfNeeded(textView: TextView){
        guard self.textView.hasEdit else { return }
        note.save(from: textView.attributedText)
        cloudManager?.upload.oldContent = note.content ?? ""
        self.textView.hasEdit = false
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
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let attrString = self.note.load()
            
            DispatchQueue.main.async {
                self.textView.attributedText = attrString
                self.textView.selectedRange.location = 0
            }
        }
        
        if let date = note.modifiedDate {
            let string = DateFormatter.sharedInstance.string(from:date)
            self.textView.setDescriptionLabel(text: string)
        }
        
        textView.contentInset.bottom = completionToolbar.bounds.height
        textView.scrollIndicatorInsets.bottom = completionToolbar.bounds.height
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
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .piano:
            
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                navigationItem.titleView = titleView
            }
            
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
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
                    DispatchQueue.main.async {
                        self.textView.setDescriptionLabel(text: string + " \(name) 님이 마지막으로 수정했습니다.")
                    }
                }
            }
        }
    }

    private func realtimeUpdate(with newNote: Note) {
        guard let current = textView.attributedText else { return }
        let mutableCurrent = NSMutableAttributedString(attributedString: current)
        let new = newNote.load()

        let insertionsFirst: (Diff.Element, Diff.Element) -> Bool = { element1, element2 -> Bool in
            switch (element1, element2) {
            case (.insert(let at1), .insert(let at2)):
                return at1 < at2
            case (.insert, .delete):
                return true
            case (.delete, .insert):
                return false
            case (.delete(let at1), .delete(let at2)):
                return at1 < at2
            }
        }

        let diff = current.string.diff(new.string)

        var insertedIndexes = [Int]()
        for element in diff {
            switch element {
            case .insert(at: let location):
                insertedIndexes.append(location)
            default:
                continue
            }
        }

        let patched = patch(from: current.string, to: new.string, sort: insertionsFirst)

        for (index, patch) in patched.enumerated() {
            switch patch {
            case .insertion(let location, let element):
                let insertedAttribute = new.attributes(at: insertedIndexes[index], effectiveRange: nil)
                let inserted = NSMutableAttributedString(string: String(element), attributes: insertedAttribute)
                inserted.addAttribute(.animatingBackground, value: true, range: NSMakeRange(0, 1))
                mutableCurrent.insert(inserted, at: location)
            default:
                continue
            }
        }

        DispatchQueue.main.async {
            self.textView.attributedText = mutableCurrent
            self.textView.selectedRange.location = 0
            self.textView.startDisplayLink()
        }
    }
}
