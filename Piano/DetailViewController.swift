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
    var mineAttrString: NSAttributedString = NSAttributedString(string: "", attributes: Preference.defaultAttr)
    
    var state: VCState = .normal
    @IBOutlet weak var detailBottomView: DetailBottomView!
    @IBOutlet weak var textAccessoryBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var defaultToolbar: UIToolbar!
    @IBOutlet weak var copyToolbar: UIToolbar!
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
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
        baseString = note.content ?? ""
        mineAttrString = NSAttributedString(string: baseString, attributes: Preference.defaultAttr)
        
        let navHeight = (navigationController?.navigationBar.bounds.height ?? 0) + Application.shared.statusBarFrame.height
        print(navHeight)
        textView.textContainerInset.bottom = navHeight
        setDelegate()
        setNavigationItems(state: state)
        addNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
        navigationController?.setToolbarHidden(true, animated: true)
        guard let textView = textView, let note = note else { return }
        if needsToUpdateUI {
            textView.setup(note: note)
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
        syncController.update(note: note, with: textView.attributedText) {}
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

//     private func setShareImage() {
//        guard let note = note else { return }
//        if let items = defaultToolbar.items {
//            for item in items {
//                if item.tag == 4 {
//                    if note.isShared {
//                        item.image = #imageLiteral(resourceName: "addPeople2")
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
        guard let theirString = note?.content, theirString != baseString else { return }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let mine = self.mineAttrString.deformatted
            let resolved = Resolver.merge(base: self.baseString, mine: mine, their: theirString)
            self.baseString = resolved
            
            DispatchQueue.main.sync {
                self.textView.attributedText = resolved.createFormatAttrString(fromPasteboard: false)
            }
        }
    }
}
