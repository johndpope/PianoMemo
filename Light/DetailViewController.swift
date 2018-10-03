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
    
    var delayCounter = 0
    var oldContent = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(note.content?.count ?? 0)
        textView.setup(note: note)
        setDelegate()
        setNavigationItems(state: state)
        discoverUserIdentity()
        textInputView.setup(viewController: self, textView: textView)
//        textAccessoryVC?.setup(textView: textView, viewController: self)
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
            let vc = des.topViewController as? MergeCollectionViewController {
            vc.originalNote = note
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
        cloudManager?.upload.oldContent = note.content ?? ""
    }

    deinit {
        print("😈")
    }
}

extension DetailViewController {
    
    private func setDelegate() {
        textView.layoutManager.delegate = self
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
                        self.textView.setDateLabel(text: string + " \(name) 님이 마지막으로 수정했습니다.".loc)
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

//            new.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, new.length), options: .longestEffectiveRangeNotRequired, using: { value, range, _ in
//                DispatchQueue.main.async {
//                    print(range)
//                    if let color = value as? UIColor {
//                        self.textView.textStorage.addAttributes([.backgroundColor : Color.highlight], range: range)
//                    }
//                }
//            })

            // 텍스트가 변경되지 않았더라도 속성이 변경된 경우 속성의 합집합을 적용한다.
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
