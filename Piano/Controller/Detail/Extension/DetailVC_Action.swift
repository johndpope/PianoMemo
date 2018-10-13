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
    
    private func setTitleView(state: VCState) {
        guard let note = note else { return }
        switch state {
        case .piano:
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                titleView.set(text: "Swipe over the text you want to copy✨".loc)
                navigationItem.titleView = titleView
            }
            
        default:
            if let titleView = view.createSubviewIfNeeded(DetailTitleView.self) {
                titleView.set(note: note)
                navigationItem.titleView = titleView
            }
        }
    }
    
    @IBAction func restore(_ sender: Any) {
        guard let note = note else { return }
        syncController.restore(note: note)
        // dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let item = sender as? UIBarButtonItem else {return}
        // TODO: 네트워크 불능이거나, 아직 업로드 안 된 경우 처리

        if let controller = cloudSharingController(item: item) {
            present(controller, animated: true, completion: nil)
        } else {
            // TODO:
            
        }
    }
    
    @IBAction func done(_ sender: Any) {
        Feedback.success()
        view.endEditing(true)
    }
    
    @IBAction func undo(_ sender: UIBarButtonItem) {
        guard let undoManager = textView.undoManager else { return }
        undoManager.undo()
        sender.isEnabled = undoManager.canUndo
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem) {
        guard let undoManager = textView.undoManager else { return }
        undoManager.redo()
        sender.isEnabled = undoManager.canRedo
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        Feedback.success()
        removeHighlight()
        setupForNormal()
    }
    
    @IBAction func tapClipboard(_ sender: Any) {
        Feedback.success()
        textView.hasEdit = true
        guard var string = UIPasteboard.general.string else {
            transparentNavigationController?.show(message: "There's no text on Clipboard!😅".loc, color: Color.trash)
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
        Feedback.success()
        setupForPiano()
    }
    
    @IBAction func copyAllButton(_ sender: Any) {
        Feedback.success()
        copyAllText()
        transparentNavigationController?.show(message: "⚡️All copy completed⚡️".loc, color: Color.point)
        removeHighlight()
        setupForNormal()
    }
    
    @IBAction func copyButton(_ sender: Any) {
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



