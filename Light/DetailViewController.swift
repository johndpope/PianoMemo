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
    case contact = 4
}
enum VCState {
    case normal
    case typing
    case piano
    case merge
    case trash
}

class DetailViewController: UIViewController, InputViewChangeable {
    
    var readOnlyTextView: TextView { return textView }
    
    var note: Note! {
        willSet {
            if newValue != nil, note != nil {
                synchronize(with: newValue)
            }
        }
    }
    
    var state: VCState = .normal
    var textAccessoryVC: TextAccessoryViewController? {
        return children.first as? TextAccessoryViewController
    }
    @IBOutlet weak var detailBottomView: DetailBottomView!
    @IBOutlet weak var textAccessoryContainerView: UIView!
    @IBOutlet weak var textAccessoryBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet var textInputView: TextInputView!
    @IBOutlet weak var defaultToolbar: UIToolbar!
    @IBOutlet weak var copyToolbar: UIToolbar!
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var kbHeight: CGFloat = 300
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    internal let locationManager = CLLocationManager()

    weak var syncController: Synchronizable!

    var delayCounter = 0
    
    lazy var recommandOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(note.content?.count ?? 0)
        textView.setup(note: note)
        setDelegate()
        setNavigationItems(state: state)
        discoverUserIdentity()
        textInputView.setup(viewController: self, textView: textView)
        textAccessoryVC?.setup(textView: textView, viewController: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerAllNotifications()
        navigationController?.setToolbarHidden(true, animated: true)
        
        //note가 hasEdit이라면 merge를 했다는 말이므로 텍스트뷰 다시 세팅하기
        if note.hasEdit {
            textView.setup(note: note)
            note.hasEdit = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unRegisterAllNotifications()
        saveNoteIfNeeded(textView: textView)
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
            let vc = des.topViewController as? MergeTableViewController {
            vc.originalNote = note
            vc.detailVC = self
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? PDFConvertViewController {
            vc.note = self.note
        }
    }

    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(textView: TextView){
        guard note.hasEdit else { return }
        note.hasEdit = false
        note.save(from: textView.attributedText)
    }

}

extension DetailViewController {
    
    private func setDelegate() {
        textView.layoutManager.delegate = self
        detailBottomView.setup(viewController: self, textView: textView)
    }

    // private func setShareImage() {
    //     if note.isShared {
    //         shareItem.image = #imageLiteral(resourceName: "addPeople2")
    //     } else {
    //         shareItem.image = #imageLiteral(resourceName: "addPeople")
    //     }
    // }

    
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
                        self.textView.setDateLabel(text: string + " Latest modified by".loc + " \(name)")
                    }
                }
            }
        }
    }


    /// 사용자가 디테일뷰컨트롤러를 보고 있는 시점에 데이터베이스가 업데이트 되는 경우
    /// 새로운 정보를 이용해 텍스트뷰를 갱신하는 함수.
    private func synchronize(with newNote: Note) {
        let resolver = ConflictResolver()
        textView.attributedText = resolver.positiveMerge(old: textView.text, new: newNote.content!).createFormatAttrString()

        // TODO: diff animation
        // 애니메이션 범위가 이상함
//        textView.attributedText = resolver.positiveMerge(old: textView.attributedText, new: newNote.content!).formatted
//
//        DispatchQueue.main.async { [weak self] in
//            self?.textView.startDisplayLink()
//        }
    }
}
