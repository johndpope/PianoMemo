//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

enum DataType: Int {
    case reminder = 0
    case calendar = 1
    case photo = 2
    case mail = 3
    case contact = 4
}

protocol DetailViewControllerDelegate: class {
    var delayQueue: [(() -> Void)]? { get set }
    func loadNotes()
}

class DetailViewController: UIViewController {
    
    var note: Note!
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var bottomView: UIView!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    var kbHeight: CGFloat!
    @IBOutlet var bottomButtons: [UIButton]!
    @IBOutlet weak var bottomViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet var containerViews: [UIView]!
    weak var delegate: DetailViewControllerDelegate!
    private var noteContentCache = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setTextView()
        setDelegate()
        setNavigationBar(state: .normal)
        saveNoteCache()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unRegisterKeyboardNotification()
        saveNoteIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateMainIfNeed()
    }
    
    
    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded(){
        guard textView.hasEdit else { return }
        var ranges: [NSRange] = []
        textView.attributedText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, textView.attributedText.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
            guard let backgroundColor = value as? Color, backgroundColor == Color.highlight else { return }
            ranges.append(range)
        }
        note.atttributes = NoteAttributes(highlightRanges: ranges)
        note.content = textView.text
        note.connectData()
        note.saveIfNeeded()
        textView.hasEdit = false

    }

}

extension DetailViewController {
    private func setDelegate() {
        textView.layoutManager.delegate = self
    }

    private func setTextView() {
        if let note = note,
            let text = note.content {
            DispatchQueue.global(qos: .userInteractive).async {
                let mutableAttrString = text.createFormatAttrString()
                
                if let noteAttribute = note.atttributes {
                    noteAttribute.highlightRanges.forEach {
                        mutableAttrString.addAttributes([.backgroundColor : Color.highlight], range: $0)
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.textView.attributedText = mutableAttrString
                }
            }
        }
        
        if let date = note.modifiedDate {
            let string = DateFormatter.sharedInstance.string(from:date)
            self.textView.setDescriptionLabel(text: string)
        }
        
        textView.contentInset.bottom = bottomViewHeight
        textView.scrollIndicatorInsets.bottom = bottomViewHeight
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
            btns.append(BarButtonItem(image: #imageLiteral(resourceName: "highlighter"), style: .plain, target: self, action: #selector(highlight(_:))))
            btns.append(BarButtonItem(image: #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:))))
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            btns.append(BarButtonItem(image: #imageLiteral(resourceName: "highlighter"), style: .plain, target: self, action: #selector(highlight(_:))))
            btns.append(BarButtonItem(image: #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:))))
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        case .piano:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(finishHighlight(_:))))
            
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                navigationItem.titleView = titleView
            }
            
            let leftBtns = [BarButtonItem(title: "", style: .plain, target: nil, action: nil)]
            
            navigationItem.setLeftBarButtonItems(leftBtns, animated: true)
        }
        
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }

    private func saveNoteCache() {
        if let content = note.content {
            noteContentCache = content
        }
    }

    private func updateMainIfNeed() {
        guard let content = self.note.content, content != noteContentCache else { return }
        delegate.delayQueue = [(() -> Void)]()
        delegate.delayQueue!.append { [weak self] in
            if let `self` = self {
                self.delegate.loadNotes()
            }
        }
    }
}
