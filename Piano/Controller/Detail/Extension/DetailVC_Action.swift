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
        var btns: [BarButtonItem] = []
        
        switch state {
        case .normal:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = false
            copyToolbar.isHidden = true
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
//            let redo = BarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .plain, target: self, action: #selector(redo(_:)))
//            if let undoManager = textView.undoManager {
//                redo.isEnabled = undoManager.canRedo
//            }
//            btns.append(redo)
//            let undo = BarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .plain, target: self, action: #selector(undo(_:)))
//            if let undoManager = textView.undoManager {
//                undo.isEnabled = undoManager.canUndo
//            }
//            btns.append(undo)
            
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = self.state != .merge ? false : true
            copyToolbar.isHidden = true
        case .piano:
            
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                titleView.set(text: "Swipe over the text you want to copy✨".loc)
                navigationItem.titleView = titleView
            }
            
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            let rightBtn = BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)
            btns.append(rightBtn)
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            defaultToolbar.isHidden = true
            copyToolbar.isHidden = false
        case .merge:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = true
            copyToolbar.isHidden = true
            
        case .trash:
            let restore = BarButtonItem(title: "Restore".loc, style: .plain, target: self, action: #selector(restore(_:)))
            btns.append(restore)
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = true
            copyToolbar.isHidden = true
        }
        
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
//    internal func setShareImage() {
//        if note.record()?.share != nil {
//            shareItem.image = #imageLiteral(resourceName: "addPeople2")
//        } else {
//            shareItem.image = #imageLiteral(resourceName: "addPeople")
//        }
//    }
    
    @IBAction func restore(_ sender: Any) {
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
        
    
    @IBAction func finishHighlight(_ sender: Any) {
        Feedback.success()
        setupForNormal()
    }
    
    @IBAction func action(_ sender: Any) {
        
    }
    
    @IBAction func plus(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        textAccessoryVC?.collectionView.indexPathsForSelectedItems?.forEach {
            textAccessoryVC?.collectionView.deselectItem(at: $0, animated: false)
        }
        
        View.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self = self else { return }
            self.textAccessoryContainerView.isHidden = !sender.isSelected
        })
        
        if !sender.isSelected {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        if sender.isSelected {
            textView.contentInset.bottom += 50
        } else {
            textView.contentInset.bottom -= 50
        }
    }
    
    @IBAction func copyModeButton(_ sender: Any) {
        Feedback.success()
        setupForPiano()
    }
    
    @IBAction func copyAllButton(_ sender: Any) {
        Feedback.success()
        copyAllText()
        transparentNavigationController?.show(message: "⚡️All copy completed⚡️".loc)
        removeHighlight()
        setupForNormal()
    }
    
    @IBAction func copyButton(_ sender: Any) {
        Feedback.success()
        let highlightedRanges = rangesForHighlightedText()
        
        guard highlightedRanges.count != 0 else {
            transparentNavigationController?.show(message: "✨Select text area to copy✨".loc)
            return//복사할 텍스트를 선택해주세요
        }
        
        copyText(in: highlightedRanges)
        transparentNavigationController?.show(message: "✨Highlighted area copied✨".loc)
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
