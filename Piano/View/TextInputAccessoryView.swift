//
//  TextInputAccessoryView.swift
//  Piano
//
//  Created by Kevin Kim on 19/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TextInputAccessoryView: UIView {

    weak var textView: DynamicTextView?
    weak var detailVC: DetailViewController?
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var redoBtn: UIButton!
    @IBOutlet weak var clipboardBtn: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerAllNotifications()
    }
    
    deinit {
        unRegisterAllNotifications()
    }
    
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func setup(detailVC: DetailViewController){
        self.detailVC = detailVC
        self.textView = detailVC.textView
        textView?.inputAccessoryView = self
        pasteboardChanged()
        changeUndoBtnState()
    }
    
    @objc func pasteboardChanged() {
        let str = UIPasteboard.general.string ?? ""
        clipboardBtn.setImage(str.count != 0 ? #imageLiteral(resourceName: "yesclipboardToolbar") : #imageLiteral(resourceName: "noclipboardToolbar"), for: .normal)
    }
    
    internal func changeUndoBtnState() {
        undoBtn.isEnabled = textView?.undoManager?.canUndo ?? false
        redoBtn.isEnabled = textView?.undoManager?.canRedo ?? false
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
    
    @IBAction func tapClipboard(_ sender: Any) {
        guard let textView = textView else { return }
        
        Feedback.success()
        textView.hasEdit = true
        textView.paste(nil)
        detailVC?.transparentNavigationController?.show(message: "⚡️Pasted at the bottom!⚡️".loc, color: Color.merge)
    }
    
    @IBAction func tapHighlight(_ sender: Any) {
        Feedback.success()
        detailVC?.setupForPiano()
    }
    @IBAction func tapDone(_ sender: Any) {
        textView?.resignFirstResponder()
    }
    
}
