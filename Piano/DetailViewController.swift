//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//
/*오늘의 할 일
 1. 전체 복사 분리
 2. 선택 복사, 오려내기 구현
 메모 분리하기 고민
 일정, 미리알림, 연락처 아키텍쳐 설계(어디까지 모듈화를 진행할 건지)
 언두 매니져 개발
*/

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
    case contact = 4
}

class DetailViewController: UIViewController, Detailable {
    enum VCState {
        case normal
        case typing
        case piano
    }
    
    var needsToUpdateUI: Bool = false
    var note: Note?
    var searchKeyword: String?
    private var contentHash: Int?
    
    var baseString: String = ""
    var mineAttrString: NSAttributedString?
    var decodedTextViewOffset: CGPoint?
    var decodedIsLandScape: Bool?
    
    var state: VCState = .normal
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var detailToolbar: DetailToolbar!
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
//    internal let locationManager = CLLocationManager()
    
    var bottomHeight: CGFloat {
        let toolbarHeight = UIScreen.main.bounds.height - detailToolbar.frame.origin.y
        return toolbarHeight
    }
    
    weak var storageService: StorageService!
    lazy var delayQueue: DelayQueue = {
        let queue = DelayQueue(delayInterval: 0.5)
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if storageService == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.storageService = appDelegate.storageService
            }
        } else {
            setup()
        }
    }

    private func setup() {
        if let note = note {
            setDelegate()
            textView.setup(note: note) { [weak self] in
                self?.mineAttrString = $0
            }
            setMetaUI(by: note)
            baseString = note.content ?? ""
            
            detailToolbar.setup(state: textView.isFirstResponder ? .typing : .normal)
            textView.contentInset.bottom = textView.isFirstResponder ? 320 : 100
            textView.scrollIndicatorInsets.bottom = textView.isFirstResponder ? 320 : 100

            setNavigationItems(state: .normal)
            addNotification()
            textView?.isHidden = false
            storageService.remote.editingNote = note
            contentHash = (note.content ?? "").hashValue
        } else {
            textView?.isHidden = true
        }

        if let offset = decodedTextViewOffset,
            !UIDevice.current.orientation.isLandscape {
            textView.setContentOffset(offset, animated: false)
        }
        if let offset = decodedTextViewOffset, let isLandscape = decodedIsLandScape {
            let current = UIDevice.current.orientation.isLandscape
            if current, isLandscape {
                textView.setContentOffset(offset, animated: false)
            } else if !current, !isLandscape {
                textView.setContentOffset(offset, animated: false)
            }
        }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        guard let note = note else { return }
        coder.encode(note.objectID.uriRepresentation(), forKey: "noteURI")
        coder.encode(textView.contentOffset, forKey: "textViewOffset")
        coder.encode(UIDevice.current.orientation.isLandscape, forKey: "isLandscape")
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        self.decodedTextViewOffset = coder.decodeCGPoint(forKey: "textViewOffset")
        self.decodedIsLandScape = coder.decodeBool(forKey: "isLandscape")
        if let url = coder.decodeObject(forKey: "noteURI") as? URL {
            storageService.local.note(url: url) { note in
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    self.note = note
                    self.setup()
                }
            }
        }
        super.decodeRestorableState(with: coder)
    }
    
    internal func setTagToNavItem() {
        guard let note = note,
            let tagBtn = navigationItem.titleView as? UIButton else { return }
        let tags = note.tags ?? ""
        if tags.count != 0 {
            tagBtn.setImage(nil, for: .normal)
            tagBtn.setTitle(tags, for: .normal)
            
        } else {
            tagBtn.setImage(#imageLiteral(resourceName: "addTag"), for: .normal)
            tagBtn.setTitle("", for: .normal)
        }
    }
    
    internal func setMetaUI(by note: Note?) {
        guard let note = note else { return }
        
        if let id = note.modifiedBy as? CKRecord.ID, note.isShared {
            CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self]
                userIdentity, error in
                guard let self = self else { return }
                if let name = userIdentity?.nameComponents?.givenName, !name.isEmpty {
                    let str = self.dateStr(from: note)
                    DispatchQueue.main.async {
                        self.textView.label.text =  str + ", Latest modified by".loc + " \(name)"
                    }
                }
            }
        } else {
            textView.label.text = dateStr(from: note)
        }
    }
    
    private func dateStr(from note: Note) -> String {
        if let date = note.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from: date)
            return string
        } else {
            return ""
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
        navigationController?.setToolbarHidden(true, animated: true)
        guard let textView = textView, let note = note else { return }
        
        
        if needsToUpdateUI {
            textView.setup(note: note) { _ in }
            setMetaUI(by: note)
            needsToUpdateUI = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToSearchKeyword()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        guard let textView = textView else { return }
        unRegisterAllNotifications()
        saveNoteIfNeeded(textView: textView)
        view.endEditing(true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? PianoEditorViewController {
            vc.note = self.note
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? AttachTagCollectionViewController {
            vc.note = self.note
            vc.detailVC = self
            vc.storageService = storageService
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? MergeTableViewController {
            vc.originNote = note
            vc.storageService = storageService
            vc.detailVC = self
            return
        }
    }

    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(textView: TextView){
        guard let note = note,
            let contentHash = contentHash,
            textView.attributedText.deformatted.hashValue != contentHash else { return }

        self.contentHash = textView.attributedText.deformatted.hashValue
        storageService.local.update(note: note, with: textView.attributedText) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, let date = note.modifiedAt else { return }
                self.textView.label.text = DateFormatter.sharedInstance.string(from: date)
            }
        }
    }
}

extension DetailViewController {

    private func addNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(merge(_:)),
            name: .resolveContent,
            object: nil
        )
    }
    
    private func setDelegate() {
        textView.layoutManager.delegate = self
        detailToolbar.detailable = self
        detailToolbar.textView = textView
    }

    @objc private func merge(_ notification: NSNotification) {
        DispatchQueue.main.sync {
            guard let note = note, let their = note.content else { return }

            let mine = textView.attributedText.deformatted
            guard mine != their else {
                baseString = mine
                return
            }
            let resolved = Resolver.merge(
                base: self.baseString,
                mine: mine,
                their: their
            )
            let attribuedString = resolved.createFormatAttrString(fromPasteboard: false)
            var caretOffset = 0
            if let selectedRange = textView.selectedTextRange {
                caretOffset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            }
            let contentOffset = textView.contentOffset

            let mineComponents = mine.utf16.map { $0 }
            let resolvedComponents = their.utf16.map { $0 }

            let patched = patch(from: mineComponents, to: resolvedComponents)

            patched.forEach {
                switch $0 {
                case let .insertion(index, element):
                    if element != 10, element != 32 {
                        textView.highlightReservedRange.append(NSMakeRange(index, 1))
                    }
                    if index < caretOffset {
                        caretOffset += 1
                    }
                case let .deletion(index):
                    if index < caretOffset {
                        caretOffset -= 1
                    }
                }
            }

            self.textView.attributedText = attribuedString
            self.textView.startDisplayLink()
            if let position = textView.position(from: textView.beginningOfDocument, offset: caretOffset) {
                self.textView.selectedTextRange = textView.textRange(from: position, to: position)
            }
            self.textView.setContentOffset(contentOffset, animated: false)
            self.baseString = resolved
            self.setMetaUI(by: self.note)
            self.setNavigationItems(state: self.state)
            self.saveNoteIfNeeded(textView: textView)
        }
    }

    private func scrollToSearchKeyword() {
        if let searchKeyword = searchKeyword,
            searchKeyword.count > 0,
            let range = textView.text.lowercased().range(of: searchKeyword.lowercased()) {
            let nsRange = textView.text.nsRange(from: range)
            textView.highlightReservedRange.append(nsRange)
            let rect = textView.layoutManager
                .boundingRect(forGlyphRange: nsRange,
                              in: textView.textContainer)
            textView.scrollRectToVisible(rect, animated: true)
            textView.startDisplayLink()
        }
    }
}

extension StringProtocol where Index == String.Index {
    func nsRange(from range: Range<Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}
