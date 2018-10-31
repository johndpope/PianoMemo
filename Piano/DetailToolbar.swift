//
//  DetailToolbar.swift
//  Piano
//
//  Created by Kevin Kim on 21/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

protocol Detailable: class {
    var note: Note? { get set }
    func setupForPiano()
    func setupForNormal()
    var transparentNavigationController: TransParentNavigationController? { get }
    func performSegue(withIdentifier: String, sender: Any?)
    var view: UIView! { get set }
    
}

class DetailToolbar: UIToolbar {
    weak var detailable: Detailable?
    weak var textView: DynamicTextView?
    @IBOutlet weak var detailToolbarBottomAnchor: LayoutConstraint!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var keyboardHeight: CGFloat?
    
    lazy var doneBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone(_:)))
    }()
    
    
    lazy var copyAllBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "copy"), style: .done, target: self, action: #selector(tapCopyAll(_:)))
    }()
    
    
    lazy var pasteBtn: UIBarButtonItem = {
       return UIBarButtonItem(image: (UIPasteboard.general.string ?? "").count == 0 ? #imageLiteral(resourceName: "noclipboardToolbar") : #imageLiteral(resourceName: "yesclipboardToolbar"), style: .done, target: self, action: #selector(tapPaste(_:)))
    }()
    
    lazy var highlightBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "highlights"), style: .done, target: self, action: #selector(tapHighlight(_:)))
    }()
    lazy var mergeBtn: UIBarButtonItem = {
       return UIBarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .done, target: self, action: #selector(tapMerge(_:)))
    }()
    
    lazy var pdfBtn: UIBarButtonItem = {
        return UIBarButtonItem(image:  #imageLiteral(resourceName: "pdf"), style: .done, target: self, action: #selector(tapPDF(_:)))
    }()
    
    lazy var clipboardBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: (UIPasteboard.general.string ?? "").count == 0 ? #imageLiteral(resourceName: "noclipboardToolbar") : #imageLiteral(resourceName: "yesclipboardToolbar"), style: .done, target: self, action: #selector(tapPasteAtSelectedRange(_:)))
    }()
    
    lazy var undoBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .done, target: self, action: #selector(tapUndo(_:)))
    }()
    
    lazy var redoBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .done, target: self, action: #selector(tapRedo(_:)))
    }()
    
    lazy var cancelBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapCancel(_:)))
    }()
    
    lazy var cutBtn: UIBarButtonItem = {
        return UIBarButtonItem(title: "오려내기", style: .done, target: self, action: #selector(tapCut(_:)))
    }()
    
    lazy var copyBtn: UIBarButtonItem = {
        return UIBarButtonItem(title: "복사하기", style: .done, target: self, action: #selector(tapCopy(_:)))
    }()
    
    lazy var fixBtn: UIBarButtonItem = {
        let fixBtn = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixBtn.width = 16
        return fixBtn
    }()
    
    let flexBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerAllNotifications()
//        setShadowImage(UIImage(), forToolbarPosition: .any)
    }
    
    deinit {
        unRegisterAllNotifications()
    }
    
    internal func setup(state: DetailViewController.VCState) {
        switch state {
        case .normal:
            setupForNormal()
        case .piano:
            setupForPiano()
        case .typing:
            setupForTyping()
        }
    }
    
    internal func changeUndoBtnState() {
//        undoBtn.isEnabled = textView?.undoManager?.canUndo ?? false
//        redoBtn.isEnabled = textView?.undoManager?.canRedo ?? false
    }
    
    private func setupForNormal() {
        pasteboardChanged()
        setItems([copyAllBtn, flexBtn, pasteBtn, flexBtn, highlightBtn, flexBtn, mergeBtn, flexBtn, pdfBtn], animated: true)
    }
    
    private func setupForTyping() {
        pasteboardChanged()
        changeUndoBtnState()
        setItems([undoBtn,fixBtn, redoBtn,fixBtn, clipboardBtn, flexBtn, doneBtn], animated: true)
    }
    
    private func setupForPiano() {
        setItems([cancelBtn, flexBtn, cutBtn, copyBtn], animated: true)
    }
    
    @IBAction func tapCopyAll(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        Feedback.success()
        copyAllText()
        detailable?.transparentNavigationController?.show(message: "⚡️All copy completed⚡️".loc, color: Color.blueNoti)
    }
    
    @IBAction func tapPaste(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        Feedback.success()
        textView?.hasEdit = true
        textView?.paste(nil)
        detailable?.transparentNavigationController?.show(message: "⚡️Pasted at the bottom!⚡️".loc, color: Color.blueNoti)
    }
    
    @IBAction func tapHighlight(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        Feedback.success()
        textView?.resignFirstResponder()
        
        detailable?.setupForPiano()
        setupForPiano()
    }
    
    @IBAction func tapMerge(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        detailable?.performSegue(withIdentifier: MergeTableViewController.identifier, sender: nil)
    }
    
    @IBAction func tapPDF(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        detailable?.performSegue(withIdentifier: PianoEditorViewController.identifier, sender: nil)
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        detailable?.setupForNormal()
        Feedback.success()
        removeHighlight()
        setupForNormal()
        
    }
    
    @IBAction func tapCut(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        Feedback.success()
        let highlightedRanges = rangesForHighlightedText()

        guard highlightedRanges.count != 0 else {
            detailable?.transparentNavigationController?.show(message: "✨Select text area to cut✨".loc, color: Color.point)
            return//오려낼 텍스트를 선택해주세요
        }

        cutText(in: highlightedRanges)
        detailable?.transparentNavigationController?.show(message: "✨Highlighted area cut✨".loc, color: Color.point)
        setupForNormal()
        detailable?.setupForNormal()
    }
    
    @IBAction func tapCopy(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        Feedback.success()
        let highlightedRanges = rangesForHighlightedText()

        guard highlightedRanges.count != 0 else {
            detailable?.transparentNavigationController?.show(message: "✨Select text area to copy✨".loc, color: Color.point)
            return//복사할 텍스트를 선택해주세요
        }

        copyText(in: highlightedRanges)
        detailable?.transparentNavigationController?.show(message: "✨Highlighted area copied✨".loc, color: Color.point)
        removeHighlight() //형광펜으로 칠해진 텍스트가 복사되었어요✨
        setupForNormal()
        detailable?.setupForNormal()
    }
    
    @IBAction func tapUndo(_ sender: Any) {
        guard let undoManager = textView?.undoManager else { return }
        undoManager.undo()
        undoBtn.isEnabled = undoManager.canUndo
    }
    
    @IBAction func tapRedo(_ sender: Any) {
        guard let undoManager = textView?.undoManager else { return }
        undoManager.redo()
        redoBtn.isEnabled = undoManager.canRedo
    }
    
    @IBAction func tapPasteAtSelectedRange(_ sender: Any) {
        guard let textView = textView else { return }

        Feedback.success()
        textView.hasEdit = true
        textView.paste(nil)
        detailable?.transparentNavigationController?.show(message: "⚡️Pasted at the bottom!⚡️".loc, color: Color.blueNoti)
    }
    
    @IBAction func tapDone(_ sender: Any) {
        guard let _ = detailable?.note else { return }
        Feedback.success()
        detailable?.view.endEditing(true)
    }
    
    private func copyText(in ranges: [NSRange]) {
        guard let textView = textView else { return }
        let highlightStrs = ranges.map {
            return textView.attributedText.attributedSubstring(from: $0).string.trimmingCharacters(in: .newlines)
        }

        let str = highlightStrs.reduce("") { (sum, str) -> String in
            guard sum.count != 0 else { return str }
            return (sum + "\n" + str)
        }

        UIPasteboard.general.string = str
        
    }
    
    private func copyAllText(){
        guard let textView = textView else { return }
        UIPasteboard.general.string = textView.text
    }
    
    private func cutText(in ranges: [NSRange]) {
        guard let textView = textView else { return }
        //복사하고
        copyText(in: ranges)
        //제거
        textView.replaceHighlightedTextToEmpty()
    }
    
    private func removeHighlight(){
        guard let textView = textView, let attrText = textView.attributedText else { return }
        var highlightedRanges: [NSRange] = []
        attrText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, attrText.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightedRanges.append(range)
        }

        highlightedRanges.forEach {
            textView.textStorage.addAttributes([.backgroundColor : Color.clear], range: $0)
        }
    }
    
    private func rangesForHighlightedText() -> [NSRange] {
        guard let attrText = textView?.attributedText else { return []}
        var highlightedRanges: [NSRange] = []
        attrText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, attrText.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightedRanges.insert(range, at: 0)
        }
        return highlightedRanges
    }

}

extension DetailToolbar {
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
    }
    
    @objc func pasteboardChanged() {
        let str = UIPasteboard.general.string ?? ""
        clipboardBtn.image = str.count != 0 ? #imageLiteral(resourceName: "yesclipboardToolbar") : #imageLiteral(resourceName: "noclipboardToolbar")
        pasteBtn.image = str.count != 0 ? #imageLiteral(resourceName: "yesclipboardToolbar") : #imageLiteral(resourceName: "noclipboardToolbar")
    }
    
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardToken?.invalidate()
        keyboardToken = nil
        setupForNormal()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height, let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }

        
        UIView.animate(withDuration: duration) { [weak self] in
            let safeInset = self?.superview?.safeAreaInsets.bottom ?? 0
            self?.detailToolbarBottomAnchor.constant = kbHeight - safeInset
            self?.setupForTyping()
            self?.frame.size.height = 44
            self?.layoutIfNeeded()
        }
        
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            let safeInset = self.superview?.safeAreaInsets.bottom ?? 0
            self.detailToolbarBottomAnchor.constant = max(UIScreen.main.bounds.height - layer.frame.origin.y - safeInset, 0)
            self.layoutIfNeeded()
        })
    }
}
