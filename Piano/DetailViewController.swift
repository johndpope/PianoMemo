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
    @IBOutlet weak var clipboardBarButton: UIBarButtonItem!
    
    var state: VCState = .normal
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var defaultToolbar: UIToolbar!
    @IBOutlet weak var copyToolbar: UIToolbar!
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
//    internal let locationManager = CLLocationManager()
    
    var bottomHeight: CGFloat {
        let toolbarHeight = UIScreen.main.bounds.height - defaultToolbar.frame.origin.y
        return toolbarHeight
    }
    
    weak var syncController: Synchronizable!
    lazy var delayQueue: DelayQueue = {
        let queue = DelayQueue(delayInterval: 1)
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
            pasteboardChanged()
            textView.setup(note: note) { [weak self] in
                self?.mineAttrString = $0
            }
            setMetaUI(by: note)
            baseString = note.content ?? ""

            textView.contentInset.bottom = 100
            textView.scrollIndicatorInsets.bottom = 100

            setDelegate()
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
    
    internal func setMetaUI(by note: Note?) {
        guard let note = note else { return }
        if let tags = note.tags {
            self.title = tags
        }
        
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
        guard let textView = textView, let note = note else { return }
        registerAllNotifications()
        navigationController?.setToolbarHidden(true, animated: true)
        
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
    }

    @objc private func merge(_ notification: NSNotification) {
        guard let theirString = note?.content,
            theirString != baseString else { return }
            DispatchQueue.main.sync {
                let mine = textView.attributedText.deformatted
                let resolved = Resolver.merge(
                    base: self.baseString,
                    mine: mine,
                    their: theirString
                )
                let attribuedString = resolved.createFormatAttrString(fromPasteboard: false)
                
                self.textView.attributedText = attribuedString
                self.baseString = resolved
                self.setMetaUI(by: self.note)
                self.setNavigationItems(state: self.state)
                self.saveNoteIfNeeded(textView: textView)
            }
    }
}
