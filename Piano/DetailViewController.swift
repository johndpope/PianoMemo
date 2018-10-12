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
enum VCState {
    case normal
    case typing
    case piano
    case merge
    case trash
}

class DetailViewController: UIViewController, TextViewType {
    var textViewRef: TextView { return textView }
    
    @objc var note: Note!
    
    var state: VCState = .normal
    @IBOutlet weak var detailBottomView: DetailBottomView!
    @IBOutlet weak var textAccessoryBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var defaultToolbar: UIToolbar!
    @IBOutlet weak var copyToolbar: UIToolbar!
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    internal let locationManager = CLLocationManager()

    weak var syncController: Synchronizable!
    var delayCounter = 0
    // 사용자가 디테일뷰를 보고 있는 동안 데이터 베이스 업데이트가 발생할 때 사용하는 base content
    private var contentCache: String?

    lazy var recommandOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let note = note else { return }
        textView.setup(note: note)
        contentCache = note.content
        setDelegate()
        setNavigationItems(state: state)
        discoverUserIdentity()
        setShareImage()
        addNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let note = note else { return }
        registerAllNotifications()
        navigationController?.setToolbarHidden(true, animated: true)
        
        //note가 hasEdit이라면 태그를 붙였다는 를 했다는 말이므로 텍스트뷰 다시 세팅하기
        if textView.hasEdit {
            textView.setup(note: note)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let _ = note else { return }
        unRegisterAllNotifications()
        if let textView = textView {
            saveNoteIfNeeded(textView: textView)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let des = segue.destination as? TextAccessoryViewController {
            des.setup(textView: textView, viewController: self)
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? PianoEditorViewController {
            vc.note = self.note
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? AttachTagCollectionViewController {
            vc.note = self.note
            vc.textView = self.textView
            vc.syncController = syncController
            return
        }
    }

    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(textView: TextView){
        guard self.textView.hasEdit else { return }
        syncController.update(note: note, with: textView.attributedText)
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
        detailBottomView.setup(viewController: self, textView: textView)
    }

     private func setShareImage() {
        if let items = defaultToolbar.items {
            for item in items {
                if item.tag == 4 {
                    if note.isShared {
                        item.image = #imageLiteral(resourceName: "addPeople2")
                    } else {
                        item.image = #imageLiteral(resourceName: "addPeople")
                        if note.recordArchive == nil {
                            item.tintColor = .gray
                            item.isEnabled = false
                        } else {
                            item.tintColor = items.first!.tintColor
                            item.isEnabled = true
                        }
                    }
                }
            }
        }
     }

    
    private func discoverUserIdentity() {
        guard note.isShared,
            let id = note.modifiedBy as? CKRecord.ID else { return }
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) {
            userIdentity, error in
            if let nameComponent = userIdentity?.nameComponents {
                let name = (nameComponent.givenName ?? "")
                if let date = self.note.modifiedAt, !name.isEmpty {
                    let string = DateFormatter.sharedInstance.string(from:date)
                    DispatchQueue.main.async {
                        self.textView.setDateLabel(text: string + ", Latest modified by".loc + " \(name)")
                    }
                }
            }
        }
    }

    @objc private func resolve(_ notification: NSNotification) {
        if let base = contentCache, let their = note.content {
            DispatchQueue.main.async { [weak self] in
                guard let self = self , base != their else { return }
                let mine = self.textView.attributedText.deformatted
                let resolved = Resolver.merge(base: base, mine: mine, their: their)
//                self.textView.text = resolved
                self.textView.attributedText = resolved.createFormatAttrString(fromPasteboard: false)
                self.contentCache = resolved
                print(base, their, mine)
//                DispatchQueue.global(qos: .utility).async {
//                    let resolved = Resolver.merge(base: base, mine: mine, their: their)
//                    DispatchQueue.main.async { [weak self] in
////                        self?.textView.text = resolved
//                        self?.contentCache = resolved
//                        self?.textView.attributedText = resolved.createFormatAttrString(fromPasteboard: false)
//                    }
//                }
            }
        }
    }
}
