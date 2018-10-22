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

class DetailViewController: UIViewController {
    enum VCState {
        case normal
        case typing
        case piano
    }
    
    var needsToUpdateUI: Bool = false
    var note: Note?
    
    var baseString: String = ""
    var mineAttrString: NSAttributedString?
    var decodedTextViewOffset: CGPoint?
    
    var state: VCState = .normal
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var detailToolbar: DetailToolbar!
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
//    internal let locationManager = CLLocationManager()
    
    var bottomHeight: CGFloat {
        let toolbarHeight = UIScreen.main.bounds.height - detailToolbar.frame.origin.y
        return toolbarHeight
    }
    
    weak var syncController: Synchronizable!
    lazy var delayQueue: DelayQueue = {
        let queue = DelayQueue(delayInterval: 2)
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if syncController == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.syncController = appDelegate.syncController
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
        } else {
            textView?.isHidden = true
        }

        if let offset = decodedTextViewOffset,
            !UIDevice.current.orientation.isLandscape {
            textView.setContentOffset(offset, animated: false)
        }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        guard let note = note else { return }
        coder.encode(note.objectID.uriRepresentation(), forKey: "noteURI")
        coder.encode(textView.contentOffset, forKey: "textViewOffset")
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        self.decodedTextViewOffset = coder.decodeCGPoint(forKey: "textViewOffset")
        if let url = coder.decodeObject(forKey: "noteURI") as? URL {
            syncController.note(url: url) { note in
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
        guard let note = note else { return }
        let tags = note.tags ?? ""
        if tags.count != 0 {
            navigationItem.rightBarButtonItem?.image = nil
            navigationItem.rightBarButtonItem?.title = tags
            
        } else {
            navigationItem.rightBarButtonItem?.title = ""
            navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "addTag")
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        guard let textView = textView else { return }
        unRegisterAllNotifications()
        saveNoteIfNeeded(textView: textView)
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
            vc.syncController = syncController
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? MergeTableViewController {
            vc.originNote = note
            vc.syncController = syncController
            vc.detailVC = self
            return
        }
    }

    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(textView: TextView){
        guard let note = note, self.textView.hasEdit else { return }
        syncController.update(note: note, with: textView.attributedText) { [weak self] in
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
        detailToolbar.detailVC = self
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
            var caretOffset: Int?
            if let selectedRange = textView.selectedTextRange {
                caretOffset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            }
            let contentOffset = textView.contentOffset

            let mineComponents = mine.utf16.map { $0 }
            let resolvedComponents = their.utf16.map { $0 }

            let diff = mineComponents.diff(resolvedComponents)
            diff.forEach {
                switch $0 {
                case let .insert(at):
                    textView.insertedRanges.append(NSMakeRange(at, 1))
                default:
                    break
                }
            }
            self.textView.attributedText = attribuedString
            self.textView.startDisplayLink()
            if let caretOffset = caretOffset,
                let position = textView.position(from: textView.beginningOfDocument, offset: caretOffset) {
                self.textView.selectedTextRange = textView.textRange(from: position, to: position)
            }
            self.textView.setContentOffset(contentOffset, animated: false)
            self.baseString = resolved
            self.setMetaUI(by: self.note)
            self.setNavigationItems(state: self.state)
            self.saveNoteIfNeeded(textView: textView)
        }
    }
}
