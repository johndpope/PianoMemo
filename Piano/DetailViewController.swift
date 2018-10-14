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
    var delayCounter = 0

//    lazy var recommandOperationQueue: OperationQueue = {
//        let queue = OperationQueue()
//        queue.maxConcurrentOperationCount = 1
//        return queue
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let note = note else { return }
        textView.setup(note: note)
        setMetaUI(by: note)
        baseString = note.content ?? ""
        
//        let navHeight = (navigationController?.navigationBar.bounds.height ?? 0) + Application.shared.statusBarFrame.height
//        print("높이: \(navHeight)")
        let bottomHeight = UIScreen.main.bounds.height - defaultToolbar.frame.origin.y
        textView.contentInset.bottom = bottomHeight
        textView.scrollIndicatorInsets.bottom = bottomHeight
        
        setDelegate()
        setNavigationItems(state: state)
        addNotification()
    }
    
    internal func setMetaUI(by note: Note) {
        
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
                        self.textView.label.text =  str + ", Latest modified by".loc + name
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
            textView.setup(note: note)
            setMetaUI(by: note)
            needsToUpdateUI = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotifications()
        guard let textView = textView else { return }
        saveNoteIfNeeded(textView: textView)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

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
            vc.detailTitleView = (navigationItem.titleView as? DetailTitleView)
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
            guard let self = self else { return }
            DispatchQueue.main.async {
                (self.navigationItem.titleView as? DetailTitleView)?.set(note: note)
            }
        }
    }

}

extension DetailViewController {

    private func addNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resolve(_:)),
            name: .resolveContent,
            object: nil
        )
    }
    
    private func setDelegate() {
        textView.layoutManager.delegate = self
    }

//     private func setShareImage() {
//        guard let note = note else { return }
//        if let items = defaultToolbar.items {
//            for item in items {
//                if item.tag == 4 {
//                    if note.isShared {
//                        item.ㅕㅔㅇimage = #imageLiteral(resourceName: "addPeople2")
//                    } else {
//                        item.image = #imageLiteral(resourceName: "addPeople")
//                        if note.recordArchive == nil {
//                            item.tintColor = .gray
//                            item.isEnabled = false
//                        } else {
//                            item.tintColor = items.first!.tintColor
//                            item.isEnabled = true
//                        }
//                    }
//                }
//            }
//        }
//     }

    @objc private func resolve(_ notification: NSNotification) {
        guard let theirString = note?.content,
            let mineAttrString = self.mineAttrString,
            theirString != baseString else { return }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let mine = mineAttrString.deformatted
            let resolved = Resolver.merge(base: self.baseString, mine: mine, their: theirString)
            self.baseString = resolved
            
            DispatchQueue.main.sync {
                self.textView.attributedText = resolved.createFormatAttrString(fromPasteboard: false)
            }
        }
    }
}
