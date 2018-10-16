//
//  DetailVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import ContactsUI
import CoreLocation

protocol ContainerDatasource {
    func reset()
    func startFetch()
    
}

extension DetailViewController {

    internal func setNavigationItems(state: VCState){
        guard let note = note else { return }
        var btns: [BarButtonItem] = []
        
        switch state {
        case .normal:
            let btn = BarButtonItem(image: note.isShared ? #imageLiteral(resourceName: "addPeople2") : #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:)))
            btns.append(btn)
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = false
            copyToolbar.isHidden = true
            
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            btns.append(BarButtonItem(image: note.isShared ? #imageLiteral(resourceName: "addPeople2") : #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:))))

            navigationItem.setLeftBarButtonItems(nil, animated: false)
            copyToolbar.isHidden = true
            
        case .piano:
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            let rightBtn = BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)
            btns.append(rightBtn)
            navigationController?.navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            defaultToolbar.isHidden = true
            copyToolbar.isHidden = false

        }
        setTitleView(state: state)
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
    internal func setTitleView(state: VCState) {
        guard let note = note else { return }
        switch state {
        case .piano:
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                titleView.set(text: "Swipe over the text you want to copy✨".loc)
                navigationItem.titleView = titleView
            }
            
        default:
            let button = UIButton(type: .system)
            let tags = note.tags ?? ""
            let title = tags
            if tags.count != 0 {
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            } else {
                button.setImage(#imageLiteral(resourceName: "addTag"), for: .normal)
            }
            
            
            button.frame.size.width = 200
            button.frame.size.height = 44
            button.addTarget(self, action: #selector(tapAttachTag(_:)), for: .touchUpInside)
            navigationItem.titleView = button
        }
    }
    
    @IBAction func restore(_ sender: Any) {
        guard let note = note else { return }
        syncController.restore(note: note) {}
        // dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let note = note,
            let item = sender as? UIBarButtonItem else {return}
        // TODO: 네트워크 불능이거나, 아직 업로드 안 된 경우 처리
        cloudSharingController(note: note, item: item) {
            [weak self] controller in
            if let self = self, let controller = controller {
                OperationQueue.main.addOperation {
                    self.present(controller, animated: true)
                }
            }
        }
    }
    
    @IBAction func tapMerge(_ sender: Any) {
        guard let _ = note else { return }
        performSegue(withIdentifier: MergeTableViewController.identifier, sender: nil)
    }
    
    @IBAction func tapAttachTag(_ sender: Any) {
        guard let _ = note else { return }
        performSegue(withIdentifier: AttachTagCollectionViewController.identifier, sender: nil)
    }
    
    @IBAction func tapPDF(_ sender: Any) {
        guard let _ = note else { return }
        performSegue(withIdentifier: PianoEditorViewController.identifier, sender: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        guard let _ = note else { return }
        Feedback.success()
        textView.resignFirstResponder()
    }
    
    @IBAction func undo(_ sender: UIBarButtonItem) {
        guard let _ = note else { return }
        guard let undoManager = textView.undoManager else { return }
        undoManager.undo()
        sender.isEnabled = undoManager.canUndo
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem) {
        guard let _ = note else { return }
        guard let undoManager = textView.undoManager else { return }
        undoManager.redo()
        sender.isEnabled = undoManager.canRedo
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        guard let _ = note else { return }
        Feedback.success()
        removeHighlight()
        setupForNormal()
    }
    
    @IBAction func tapClipboard(_ sender: Any) {
        guard let _ = note else { return }
        Feedback.success()
        textView.hasEdit = true
        guard var string = UIPasteboard.general.string else {
            transparentNavigationController?.show(message: "There's no text on Clipboard. 😅".loc, color: Color.trash)
            return }
        let count = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count
        string = count != 0
            ? "\n" + string
            : string
        let attrString = string.createFormatAttrString(fromPasteboard: true)
        let range = NSMakeRange(textView.attributedText.length, 0)
        textView.textStorage.replaceCharacters(in: range, with: attrString)
        textView.insertText("")
        transparentNavigationController?.show(message: "⚡️Pasted at the bottom!⚡️".loc, color: Color.merge)
        
        scrollTextViewToBottom(textView: textView)
    }
    
    func scrollTextViewToBottom(textView: UITextView) {
        if textView.attributedText.length > 0 {
            let location = textView.attributedText.length - 1
            let bottom = NSMakeRange(location, 1)
            textView.scrollRangeToVisible(bottom)
        }
    }

    @IBAction func copyModeButton(_ sender: Any) {
        guard let _ = note else { return }
        Feedback.success()
        setupForPiano()
    }
    
    @IBAction func copyAllButton(_ sender: Any) {
        guard let _ = note else { return }
        Feedback.success()
        copyAllText()
        transparentNavigationController?.show(message: "⚡️All copy completed⚡️".loc, color: Color.point)
        removeHighlight()
        setupForNormal()
    }
    
    @IBAction func copyButton(_ sender: Any) {
        guard let _ = note else { return }
        Feedback.success()
        let highlightedRanges = rangesForHighlightedText()
        
        guard highlightedRanges.count != 0 else {
            transparentNavigationController?.show(message: "✨Select text area to copy✨".loc, color: Color.point)
            return//복사할 텍스트를 선택해주세요
        }
        
        copyText(in: highlightedRanges)
        transparentNavigationController?.show(message: "✨Highlighted area copied✨".loc, color: Color.point)
        removeHighlight() //형광펜으로 칠해진 텍스트가 복사되었어요✨
        setupForNormal()
    }
    
    private func removeHighlight(){
        guard let attrText = textView.attributedText else { return }
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
        guard let attrText = textView.attributedText else { return []}
        var highlightedRanges: [NSRange] = []
        attrText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, attrText.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightedRanges.insert(range, at: 0)
        }
        return highlightedRanges
        
    }
    
    private func copyText(in range: [NSRange]) {
        let highlightStrs = range.map {
            return textView.attributedText.attributedSubstring(from: $0).string.trimmingCharacters(in: .newlines)
        }
        
        let str = highlightStrs.reduce("") { (sum, str) -> String in
            guard sum.count != 0 else { return str }
            return (sum + "\n" + str)
        }
        
        UIPasteboard.general.string = str
        
    }
    
    private func copyAllText(){
        UIPasteboard.general.string = textView.text
    }
    
    
}

extension DetailViewController: CLLocationManagerDelegate {
    
}



