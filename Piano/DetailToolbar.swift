//
//  DetailToolbar.swift
//  Piano
//
//  Created by Kevin Kim on 21/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

protocol StorageServiceable{
    var storageService: StorageService! { get set }
}

class DetailToolbar: UIToolbar {
    weak var pianoEditorView: PianoEditorView?
    @IBOutlet weak var detailToolbarBottomAnchor: LayoutConstraint!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var keyboardHeight: CGFloat?
    
    lazy var doneBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone(_:)))
    }()
    
    lazy var finishBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapFinish(_:)))
    }()
    
    lazy var trashBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapTrash(_:)))
    }()
    
    lazy var deleteBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapDelete(_:)))
    }()
    
    lazy var copyAllBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "copy"), style: .done, target: self, action: #selector(tapCopyAll(_:)))
    }()
    
    lazy var screenAreaBtn: UIBarButtonItem = {
        return UIBarButtonItem(title: "화면 영역 선택", style: .plain, target: self, action: #selector(tapSelectScreenArea(_:)))
    }()
    
    lazy var highlightBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "highlights"), style: .done, target: self, action: #selector(tapHighlight(_:)))
    }()
    lazy var mergeBtn: UIBarButtonItem = {
       return UIBarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .done, target: self, action: #selector(tapMerge(_:)))
    }()
    
    lazy var commentBtn: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tapComment(_:)))
    }()
    
    lazy var pdfBtn: UIBarButtonItem = {
        return UIBarButtonItem(image:  #imageLiteral(resourceName: "pdf"), style: .done, target: self, action: #selector(tapPDF(_:)))
    }()
    
    lazy var pasteAtBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "yesclipboardToolbar"), style: .done, target: self, action: #selector(tapPasteAt(_:)))
    }()
    
    lazy var copyAtBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "copy"), style: .done, target: self, action: #selector(tapCopyAt(_:)))
    }()
    
    lazy var cutAtBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "cut"), style: .done, target: self, action: #selector(tapCutAt(_:)))
    }()
    
    lazy var undoBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .done, target: self, action: #selector(tapUndo(_:)))
    }()
    
    lazy var redoBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .done, target: self, action: #selector(tapRedo(_:)))
    }()
    
    lazy var cutBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "cut"), style: .done, target: self, action: #selector(tapCut(_:)))
    }()
    
    lazy var copyBtn: UIBarButtonItem = {
        return UIBarButtonItem(image: #imageLiteral(resourceName: "copy"), style: .plain, target: self, action: #selector(tapCopy(_:)))
    }()
    
    lazy var permanentDeleteBtn: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Delete".loc, style: .plain, target: self, action: #selector(tapPermanentDelete(_:)))
        btn.tintColor = Color.red
        return btn
    }()
    
    lazy var restoreBtn: UIBarButtonItem = {
        return UIBarButtonItem(title: "Restore".loc, style: .plain, target: self, action: #selector(tapRestore(_:)))
    }()
    
    lazy var marginBtn: UIBarButtonItem = {
        let marginBtn = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        marginBtn.width = 16
        return marginBtn
    }()
    
    lazy var doubleMarginBtn: UIBarButtonItem = {
        let doubleMarginBtn = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        doubleMarginBtn.width = 20
        return doubleMarginBtn
    }()
    
    let flexBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setShadowImage(UIImage(), forToolbarPosition: .any)
        setBackgroundImage(#imageLiteral(resourceName: "navBackground"), forToolbarPosition: .any, barMetrics: .default)
    }
    
    internal func setup(state: PianoEditorView.TableViewState) {
        switch state {
        case .normal:
            setupForNormal()
        case .piano:
            setupForPiano()
        case .typing:
            setupForTyping()
        case .editing:
            setupForEditing()
        case .trash:
            setupForTrash()
        case .readOnly:
            setupForReadOnly()
        }
    }
    
    internal func changeUndoBtnsState() {
//        undoBtn.isEnabled = textView?.undoManager?.canUndo ?? false
//        redoBtn.isEnabled = textView?.undoManager?.canRedo ?? false
    }
    
    internal func changeEditingBtnsState(count: Int) {
        let isEnabled = count != 0
        copyBtn.isEnabled = isEnabled
        cutBtn.isEnabled = isEnabled
        deleteBtn.isEnabled = isEnabled
    }
    
    internal func changeEditingAtBtnsState(count: Int) {
        let isEnabled = count != 0
        copyAtBtn.isEnabled = isEnabled
        cutAtBtn.isEnabled = isEnabled
    }
    
    private func setupForNormal() {
        setItems([trashBtn, flexBtn, copyAllBtn, flexBtn, highlightBtn, flexBtn, mergeBtn, flexBtn, pdfBtn], animated: true)
    }
    
    private func setupForEditing() {
        let count = pianoEditorView?.tableView.indexPathsForSelectedRows?.count ?? 0
        changeEditingBtnsState(count: count)
        setItems([screenAreaBtn, flexBtn, copyBtn, marginBtn, cutBtn, marginBtn, deleteBtn], animated: true)
    }
    
    private func setupForTrash() {
        setItems([restoreBtn, flexBtn, permanentDeleteBtn], animated: true)
    }
    
    private func setupForReadOnly() {
        
    }
    
    private func setupForTyping() {
//        changeUndoBtnsState()
        //undoBtn, marginBtn, redoBtn, doubleMarginBtn,
        setItems([copyAtBtn, marginBtn, cutAtBtn, marginBtn, pasteAtBtn, flexBtn, doneBtn], animated: true)
    }
    
    private func setupForPiano() {
        setItems([flexBtn, finishBtn, flexBtn], animated: true)
    }
    
    @IBAction func tapFinish(_ sender: Any) {
        pianoEditorView?.state = .normal
    }
    
    @IBAction func tapCopyAll(_ sender: Any) {
        guard let vc = pianoEditorView?.viewController,
            var strArray = pianoEditorView?.dataSource.first else { return }
        
        Feedback.success()
        if strArray.count < Preference.paraLimit {
            strArray = strArray.map { $0.convertKeyToEmoji() }
        }
        
        vc.transparentNavigationController?.show(message: "⚡️All copy completed⚡️".loc, color: Color.point)
        
        UIPasteboard.general.string = strArray.joined(separator: "\n")
        
    }
    
    @IBAction func tapPDF(_ sender: Any) {
        //백그라운드 쓰레드로 PDF 만들고, 메인쓰레드에서는 인디케이터 표시해주고, 완료되면 performSegue로 보내서 확인시키고 그다음 전달하자
        
        guard let vc = pianoEditorView?.viewController,
            let strArray = pianoEditorView?.dataSource.first else { return }
        
        vc.showActivityIndicator()
        
        DispatchQueue.global().async {
            let resultMutableAttrString = NSMutableAttributedString(string: "")
            strArray.forEach {
                //헤더 키가 있다면, 헤더 키를 제거하고, 헤더 폰트를 대입해준다.
                //헤더 키가 없고, 불렛 키가 있다면, 불렛 키를 불렛 밸류로 만들어주고, 문단 스타일을 적용시킨다.
                //피아노 키가 있다면 형광펜으로 대체시킨다.
                let mutableAttrStr = NSMutableAttributedString(string: $0, attributes: FormAttribute.defaultAttrForPDF)
                if let headerKey = HeaderKey(text: $0, selectedRange: NSMakeRange(0, 0)) {
                    mutableAttrStr.replaceCharacters(in: headerKey.rangeToRemove, with: "")
                    mutableAttrStr.addAttributes([.font : headerKey.fontForPDF,
                                                  .paragraphStyle : headerKey.paraStyleForPDF()], range: NSMakeRange(0, mutableAttrStr.length))
                    
                } else if let bulletKey = PianoBullet(type: .key, text: $0, selectedRange: NSMakeRange(0, 0)) {
                    if bulletKey.isOn {
                        mutableAttrStr.addAttributes(FormAttribute.strikeThroughAttr, range: NSMakeRange(bulletKey.baselineIndex, mutableAttrStr.length - bulletKey.baselineIndex))
                    }
                    
                    let bulletValueAttrStr = NSAttributedString(string: bulletKey.value, attributes: FormAttribute.formAttrForPDF)
                    mutableAttrStr.replaceCharacters(in: bulletKey.range, with: bulletValueAttrStr)
                    mutableAttrStr.addAttributes([.paragraphStyle : bulletKey.paraStyleForPDF()], range: NSMakeRange(0, mutableAttrStr.length))
                }
                
                while true {
                    guard let highlightKey = HighlightKey(text: mutableAttrStr.string, selectedRange: NSMakeRange(0, mutableAttrStr.length)) else { break }
                    
                    mutableAttrStr.addAttributes([.backgroundColor : Color.highlight], range: highlightKey.range)
                    mutableAttrStr.replaceCharacters(in: highlightKey.endDoubleColonRange, with: "")
                    mutableAttrStr.replaceCharacters(in: highlightKey.frontDoubleColonRange, with: "")
                }
                
                mutableAttrStr.append(NSAttributedString(string: "\n", attributes: FormAttribute.defaultAttrForPDF))
                resultMutableAttrString.append(mutableAttrStr)
            }
            
            resultMutableAttrString.replaceCharacters(in: NSMakeRange(resultMutableAttrString.length - 1, 1), with: "")
            
            
            DispatchQueue.main.async {
                let printFormatter = UISimpleTextPrintFormatter(attributedText: resultMutableAttrString)
                let renderer = UIPrintPageRenderer()
                renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
                // A4 size
                let pageSize = CGSize(width: 595.2, height: 841.8)
                
                // Use this to get US Letter size instead
                // let pageSize = CGSize(width: 612, height: 792)
                
                // create some sensible margins
                let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
                
                // calculate the printable rect from the above two
                let printableRect = CGRect(x: pageMargins.left, y: pageMargins.top, width: pageSize.width - pageMargins.left - pageMargins.right, height: pageSize.height - pageMargins.top - pageMargins.bottom)
                
                // and here's the overall paper rectangle
                let paperRect = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
                
                renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
                renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
                
                let pdfData = NSMutableData()
                
                UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
                renderer.prepare(forDrawingPages: NSMakeRange(0, renderer.numberOfPages))
                
                let bounds = UIGraphicsGetPDFContextBounds()
                
                for i in 0  ..< renderer.numberOfPages {
                    UIGraphicsBeginPDFPage()
                    
                    renderer.drawPage(at: i, in: bounds)
                }
                
                UIGraphicsEndPDFContext()
                
                vc.performSegue(withIdentifier: PDFDetailViewController.identifier, sender: pdfData as Data)
                vc.hideActivityIndicator()
            }
            
        }
        
    }

    
    
    @IBAction func tapTrash(_ sender: Any) {
        //현재 뷰 컨트롤러를 팝하고 끝났을 때 지우기
        guard let pianoEditorView = pianoEditorView,
            let vc = pianoEditorView.viewController,
            let navController = vc.navigationController,
            let note = pianoEditorView.note else { return }
        
        Feedback.success()
        navController.popViewController(animated: true)
        pianoEditorView.storageService?.local.remove(note: note)
        
    }
    
    @IBAction func tapHighlight(_ sender: Any) {
        pianoEditorView?.state = .piano
    }
    
    @IBAction func tapMerge(_ sender: Any) {
        pianoEditorView?.viewController?.performSegue(withIdentifier: MergeTableViewController.identifier, sender: nil)
    }
    
    @IBAction func tapComment(_ sender: Any) {
        
    }
    
    @IBAction func tapSelectScreenArea(_ sender: Any) {
        guard let pianoEditorView = pianoEditorView,
            let indexPathsForVisibleRows = pianoEditorView.tableView.indexPathsForVisibleRows else { return }
        
        indexPathsForVisibleRows.forEach {
            pianoEditorView.tableView.selectRow(at: $0, animated: true, scrollPosition: .none)
        }
        
        changeEditingBtnsState(count: pianoEditorView.tableView.indexPathsForSelectedRows?.count ?? 0)
    }
    
    @IBAction func tapCopy(_ sender: Any) {
        //선택된 것들을 소트해서 스트링 배열을 만들고, 조인해서 클립보드에 넣는다.
        guard let pianoEditorView = pianoEditorView,
            let indexPathsForSelectedRows = pianoEditorView.tableView.indexPathsForSelectedRows?.sorted() else { return }
        let strs = indexPathsForSelectedRows.map {
            return pianoEditorView.dataSource[$0.section][$0.row]
        }
        
        UIPasteboard.general.string = strs.joined(separator: "\n")
        pianoEditorView.viewController?.transparentNavigationController?.show(message: "✨선택된 영역이 복사되었습니다✨".loc, color: Color.point)
        pianoEditorView.state = .normal
    }
    
    @IBAction func tapCut(_ sender: Any) {
        Feedback.success()
        guard let pianoEditorView = pianoEditorView,
            let indexPathsForSelectedRows = pianoEditorView.tableView.indexPathsForSelectedRows?.sorted() else { return }
        let strs = indexPathsForSelectedRows.map {
            return pianoEditorView.dataSource[$0.section][$0.row]
        }
        UIPasteboard.general.string = strs.joined(separator: "\n")
        
        let reversedIndexPathsForSelectedRows = indexPathsForSelectedRows.reversed()
        reversedIndexPathsForSelectedRows.forEach {
            pianoEditorView.dataSource[$0.section].remove(at: $0.row)
        }
        pianoEditorView.tableView.deleteRows(at: indexPathsForSelectedRows, with: .automatic)
        pianoEditorView.viewController?.transparentNavigationController?.show(message: "✨선택된 영역이 오려졌습니다✨".loc, color: Color.point.withAlphaComponent(0.85))
        pianoEditorView.state = .normal
    }
    
    @IBAction func tapDelete(_ sender: Any) {
        //선택된 것들을 오른차순으로 정리해서, 데이터소스에서 지우고 테이블 뷰에서도 지운다.
        Feedback.success()
        guard let pianoEditorView = pianoEditorView,
            let indexPathsForSelectedRows = pianoEditorView.tableView.indexPathsForSelectedRows?.sorted(by: { (left, right) -> Bool in
                return left.row > right.row
            }) else { return }
        
        indexPathsForSelectedRows.forEach {
            pianoEditorView.dataSource[$0.section].remove(at: $0.row)
        }
        
        pianoEditorView.tableView.deleteRows(at: indexPathsForSelectedRows, with: .automatic)
        pianoEditorView.viewController?.transparentNavigationController?.show(message: "✨선택된 영역이 삭제되었습니다✨".loc, color: Color.red)
        pianoEditorView.state = .normal
    }
    
    @IBAction func tapUndo(_ sender: Any) {
//        guard let undoManager = textView?.undoManager else { return }
//        undoManager.undo()
//        undoBtn.isEnabled = undoManager.canUndo
    }
    
    @IBAction func tapRedo(_ sender: Any) {
//        undoManager.redo()
//        redoBtn.isEnabled = undoManager.canRedo
    }
    
    @IBAction func tapPasteAt(_ sender: Any) {
        //TODO: 현재 텍스트 뷰 찾아내서 paste 호출하기
        guard let pianoEditorView = pianoEditorView else { return }
        
        for cell in pianoEditorView.tableView.visibleCells {
            if let blockCell = cell as? BlockCell, blockCell.textView.isFirstResponder {
                blockCell.textView.paste(nil)
                pianoEditorView.hasEdit = true
                return
            }
        }
        
        pianoEditorView.viewController?.transparentNavigationController?.show(message: "복사하기 위해서는 선택영역이 화면에 보여져야합니다😘".loc, color: Color.point.withAlphaComponent(0.85))
    }
    
    @IBAction func tapCopyAt(_ sender: Any) {
        guard let pianoEditorView = pianoEditorView else { return }
        
        for cell in pianoEditorView.tableView.visibleCells {
            if let blockCell = cell as? BlockCell,
                let textView = blockCell.textView,
                textView.isFirstResponder,
                textView.selectedRange.length != 0 {
                let text = (textView.text as NSString).substring(with: textView.selectedRange)
                UIPasteboard.general.string = text
                textView.selectedRange = NSMakeRange(textView.selectedRange.upperBound, 0)
                return
            }
        }
        
        pianoEditorView.viewController?.transparentNavigationController?.show(message: "복사하기 위해서는 선택영역이 화면에 보여져야합니다😘".loc, color: Color.point.withAlphaComponent(0.85))
    }
    
    @IBAction func tapCutAt(_ sender: Any) {
        guard let pianoEditorView = pianoEditorView else { return }
        
        for cell in pianoEditorView.tableView.visibleCells {
            if let blockCell = cell as? BlockCell,
                let textView = blockCell.textView,
                textView.isFirstResponder,
                textView.selectedRange.length != 0 {
                let text = (textView.text as NSString).substring(with: textView.selectedRange)
                UIPasteboard.general.string = text
                textView.replaceCharacters(in: textView.selectedRange, with: NSAttributedString(string: "", attributes: FormAttribute.defaultAttr))
                return
            }
        }
        
        pianoEditorView.viewController?.transparentNavigationController?.show(message: "오려내기 위해서는 선택영역이 화면에 보여져야합니다😘".loc, color: Color.point.withAlphaComponent(0.85))
    }
    
    @IBAction func tapPermanentDelete(_ sender: Any) {
        guard let pianoEditorView = pianoEditorView, let note = pianoEditorView.note else { return }
        pianoEditorView.viewController?.navigationController?.popViewController(animated: true)
        pianoEditorView.storageService?.local.purge(notes: [note])
    }
    
    @IBAction func tapRestore(_ sender: Any) {
        guard let pianoEditorView = pianoEditorView, let note = pianoEditorView.note else { return }
        pianoEditorView.storageService?.local.restore(note: note)
        pianoEditorView.viewController?.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapDone(_ sender: Any) {
        Feedback.success()
        pianoEditorView?.endEditing(true)
    }
    
    internal func setActivateInteraction() {
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.detailToolbarBottomAnchor.constant = max(UIScreen.main.bounds.height - layer.frame.origin.y - self.safeAreaInsets.bottom, 0)
            self.layoutIfNeeded()
        })
    }
    
    internal func setInvalidateInteraction() {
        keyboardToken?.invalidate()
        keyboardToken = nil
    }
    
    internal func animateForTyping(duration: TimeInterval, kbHeight: CGFloat) {
        guard let superView = superview else { return }
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.detailToolbarBottomAnchor.constant = kbHeight - superView.safeAreaInsets.bottom
            self.frame.size.height = 44
            superView.layoutIfNeeded()
        }
    }

}
