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
    
    private var oldAttributes: NoteAttributes!
    var note: Note! {
        didSet {
            if oldValue != nil, note != nil {
                oldAttributes = oldValue.atttributes
                synchronize(with: note)
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
            let vc = navVC.topViewController as? NoteEditable {
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

    deinit {
        print("😈")
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
            shareItem.image = #imageLiteral(resourceName: "addPeople2")
        } else {
            shareItem.image = #imageLiteral(resourceName: "addPeople")
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


    /// 사용자가 디테일뷰컨트롤러를 보고 있는 시점에 데이터베이스가 업데이트 되는 경우
    /// 새로운 정보를 이용해 텍스트뷰를 갱신하는 함수.
    private func synchronize(with newNote: Note) {
        guard let current = textView.attributedText else { return }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let `self` = self else { return }
            let new = newNote.load()
            let diff = current.string.utf16.diff(new.string.utf16)

            if diff.count > 0 {
                var insertedIndexes = [Int]()
                for element in diff {
                    switch element {
                    case .insert(at: let location):
                        insertedIndexes.append(location)
                    default:
                        continue
                    }
                }

                let patched = patch(from: current.string.utf16, to: new.string.utf16, sort: self.insertionsFirst)

                for (index, patch) in patched.enumerated() {
                    switch patch {
                    case .insertion(let location, let element):
                        if let scalar = UnicodeScalar(element) {
                            let string = String(scalar)
                            let insertedAttribute = new.attributes(at: insertedIndexes[index], effectiveRange: nil)
                            let inserted = NSMutableAttributedString(string: string, attributes: insertedAttribute)
                            if !(string.trimmingCharacters(in: .whitespaces).count == 0) {
                                inserted.addAttribute(.animatingBackground, value: true, range: NSMakeRange(0, string.count))
                            }
                            DispatchQueue.main.async { [weak self] in
                                self?.textView.textStorage.insert(inserted, at: location)
                                self?.textView.startDisplayLink()
                            }
                        }
                    case .deletion(let location):
                        DispatchQueue.main.async { [weak self] in
                            self?.textView.textStorage.deleteCharacters(in: NSMakeRange(location, 1))
                            self?.textView.startDisplayLink()
                        }
                    }
                }
            }

            // 텍스트가 변경되지 않았더라도 속성이 변경된 경우 속성의 합집합을 적용한다.
            if let oldAttributes = self.oldAttributes, let newAttributes = newNote.atttributes {
                let union = Set(oldAttributes.highlightRanges).union(newAttributes.highlightRanges)
                DispatchQueue.main.async { [weak self] in
                    union.forEach {
                        self?.textView.textStorage.addAttributes([.backgroundColor : Color.highlight], range: $0)
                    }
                }
            }
        }
    }

    // patch 순서를 결정하는 정렬 함수.
    private func insertionsFirst(element1: Diff.Element, element2: Diff.Element) -> Bool {
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
}
