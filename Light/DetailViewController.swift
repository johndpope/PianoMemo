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

class DetailViewController: UIViewController {
    
    var note: Note! {
        willSet {
            if newValue != nil, note != nil {
                synchronize(with: newValue)
            }
        }
    }
    
    @IBOutlet weak var textAccessoryBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet var textInputView: TextInputView!
    @IBOutlet var accessoryButtons: [UIButton]!
    @IBOutlet weak var textAccessoryView: UIScrollView!
    @IBOutlet weak var completionToolbar: UIToolbar!
    @IBOutlet weak var shareItem: UIBarButtonItem!
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var kbHeight: CGFloat = 300
    internal var selectedRange: NSRange = NSMakeRange(0, 0)
    internal let locationManager = CLLocationManager()

    weak var syncController: Synchronizable!

    var delayCounter = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setTextView()
        setDelegate()
        setNavigationBar(state: .normal)
        setShareImage()
        discoverUserIdentity()
        textInputView.setup(viewController: self, textView: textView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotification()
        navigationController?.setToolbarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unRegisterKeyboardNotification()
        saveNoteIfNeeded(textView: textView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
 
    }

    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(textView: TextView){
        guard self.textView.hasEdit else { return }
        syncController.update(note: note, with: textView.attributedText) { [weak self] note in
            self?.textView.hasEdit = false
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self](context) in
            guard let `self` = self else { return }
            self.textView.textContainerInset = EdgeInsets(top: 30, left: self.view.marginLeft, bottom: 100, right: self.view.marginRight)
            
            guard !self.textView.isSelectable,
                let pianoControl = self.textView.pianoControl,
                let pianoView = self.pianoView else { return }
            self.connect(pianoView: pianoView, pianoControl: pianoControl, textView: self.textView)
            pianoControl.attach(on: self.textView)
        }
    }
}

extension DetailViewController {
    
    private func setDelegate() {
        textView.layoutManager.delegate = self
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
        
        if let date = note.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from:date)
            self.textView.setDateLabel(text: string)
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
            let redo = BarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .plain, target: self, action: #selector(redo(_:)))
            if let undoManager = textView.undoManager {
                redo.isEnabled = undoManager.canRedo
            }
            btns.append(redo)
            let undo = BarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .plain, target: self, action: #selector(undo(_:)))
            if let undoManager = textView.undoManager {
                undo.isEnabled = undoManager.canUndo
            }
            btns.append(undo)
            
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
    
    private func setShareImage() {
        if note.isShared {
            shareItem.image = #imageLiteral(resourceName: "addPeople2")
        } else {
            shareItem.image = #imageLiteral(resourceName: "addPeople")
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
                        self.textView.setDateLabel(text: string + " \(name) 님이 마지막으로 수정했습니다.")
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
