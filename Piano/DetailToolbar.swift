//
//  DetailToolbar.swift
//  Piano
//
//  Created by Kevin Kim on 21/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class DetailToolbar: UIToolbar {
    weak var detail2ViewController: Detail2ViewController?
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
    
    internal func setup(state: Detail2ViewController.VCState) {
        switch state {
        case .normal:
            setupForNormal()
        case .piano:
            setupForPiano()
        case .typing:
            setupForTyping()
        case .editing:
            setupForEditing()
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
    
    private func setupForNormal() {
        setItems([trashBtn, flexBtn, copyAllBtn, flexBtn, highlightBtn, flexBtn, mergeBtn, flexBtn, pdfBtn], animated: true)
    }
    
    private func setupForEditing() {
        let count = detail2ViewController?.tableView.indexPathsForSelectedRows?.count ?? 0
        changeEditingBtnsState(count: count)
        setItems([screenAreaBtn, flexBtn, copyBtn, marginBtn, cutBtn, marginBtn, deleteBtn], animated: true)
    }
    
    private func setupForTyping() {
        changeUndoBtnsState()
        setItems([undoBtn, marginBtn, redoBtn, doubleMarginBtn, copyAtBtn, marginBtn, cutAtBtn, marginBtn, pasteAtBtn, flexBtn, doneBtn], animated: true)
    }
    
    private func setupForPiano() {
        setItems([flexBtn, finishBtn, flexBtn], animated: true)
    }
    
    @IBAction func tapFinish(_ sender: Any) {
        detail2ViewController?.state = .normal
    }
    
    @IBAction func tapCopyAll(_ sender: Any) {
        guard let detailVC = detail2ViewController,
            var strArray = detailVC.dataSource.first else { return }
        
        Feedback.success()
        if strArray.count < Preference.paraLimit {
            strArray = strArray.map { $0.convertKeyToEmoji() }
        }
        detail2ViewController?.transparentNavigationController?.show(message: "⚡️All copy completed⚡️".loc, color: Color.point)
        
        UIPasteboard.general.string = strArray.joined(separator: "\n")
        
    }
    
    @IBAction func tapPDF(_ sender: Any) {
        //백그라운드 쓰레드로 PDF 만들고, 메인쓰레드에서는 인디케이터 표시해주고, 완료되면 performSegue로 보내서 확인시키고 그다음 전달하자
        
        guard let detailVC = detail2ViewController,
            let strArray = detailVC.dataSource.first else { return }
        
        detailVC.showActivityIndicator()
        
        DispatchQueue.global().async {
            let resultMutableAttrString = NSMutableAttributedString(string: "")
            strArray.forEach {
                //헤더 키가 있다면, 헤더 키를 제거하고, 헤더 폰트를 대입해준다.
                //헤더 키가 없고, 불렛 키가 있다면, 불렛 키를 불렛 밸류로 만들어주고, 문단 스타일을 적용시킨다.
                //피아노 키가 있다면 형광펜으로 대체시킨다.
                let mutableAttrStr = NSMutableAttributedString(string: $0, attributes: FormAttribute.defaultAttrForPDF)
                if let headerKey = HeaderKey(text: $0, selectedRange: NSMakeRange(0, 0)) {
                    mutableAttrStr.replaceCharacters(in: headerKey.rangeToRemove, with: "")
                    mutableAttrStr.addAttributes([.font : headerKey.fontForPDF], range: NSMakeRange(0, mutableAttrStr.length))
                    
                } else if let bulletKey = BulletKey(text: $0, selectedRange: NSMakeRange(0, 0)) {
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
                
                resultMutableAttrString.append(mutableAttrStr)
            }
            
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
            
            detailVC.performSegue(withIdentifier: PDFDetailViewController.identifier, sender: pdfData as Data)
            
            detailVC.hideActivityIndicator()
        }
        
    }

    
    
    @IBAction func tapTrash(_ sender: Any) {
        //현재 뷰 컨트롤러를 팝하고 끝났을 때 지우기
        guard let detailVC = detail2ViewController,
            let navController = detailVC.navigationController,
            let note = detailVC.note else { return }
        
        Feedback.success()
        navController.popViewController(animated: true)
        detailVC.storageService.local.remove(note: note, completion: {})
        
    }
    
    @IBAction func tapHighlight(_ sender: Any) {
        detail2ViewController?.state = .piano
    }
    
    @IBAction func tapMerge(_ sender: Any) {
        detail2ViewController?.performSegue(withIdentifier: MergeTableViewController.identifier, sender: nil)
    }
    
    @IBAction func tapComment(_ sender: Any) {
        
    }
    
    @IBAction func tapSelectScreenArea(_ sender: Any) {
        guard let detailVC = detail2ViewController,
            let indexPathsForVisibleRows = detailVC.tableView.indexPathsForVisibleRows else { return }
        
        indexPathsForVisibleRows.forEach {
            detailVC.tableView.selectRow(at: $0, animated: true, scrollPosition: .none)
        }
        
        changeEditingBtnsState(count: detailVC.tableView.indexPathsForSelectedRows?.count ?? 0)
    }
    
    @IBAction func tapCopy(_ sender: Any) {
        //선택된 것들을 소트해서 스트링 배열을 만들고, 조인해서 클립보드에 넣는다.
        guard let detailVC = detail2ViewController,
            let indexPathsForSelectedRows = detailVC.tableView.indexPathsForSelectedRows?.sorted() else { return }
        let strs = indexPathsForSelectedRows.map {
            return detailVC.dataSource[$0.section][$0.row]
        }
        
        UIPasteboard.general.string = strs.joined(separator: "\n")
        detailVC.transparentNavigationController?.show(message: "✨선택된 영역이 복사되었습니다✨".loc, color: Color.point)
        detailVC.state = .normal
    }
    
    @IBAction func tapCut(_ sender: Any) {
        Feedback.success()
        guard let detailVC = detail2ViewController,
            let indexPathsForSelectedRows = detailVC.tableView.indexPathsForSelectedRows?.sorted() else { return }
        let strs = indexPathsForSelectedRows.map {
            return detailVC.dataSource[$0.section][$0.row]
        }
        UIPasteboard.general.string = strs.joined(separator: "\n")
        
        let reversedIndexPathsForSelectedRows = indexPathsForSelectedRows.reversed()
        reversedIndexPathsForSelectedRows.forEach {
            detailVC.dataSource[$0.section].remove(at: $0.row)
        }
        detailVC.tableView.deleteRows(at: indexPathsForSelectedRows, with: .automatic)
        detailVC.transparentNavigationController?.show(message: "✨선택된 영역이 오려졌습니다✨".loc, color: Color.yellow)
        detailVC.state = .normal
    }
    
    @IBAction func tapDelete(_ sender: Any) {
        //선택된 것들을 오른차순으로 정리해서, 데이터소스에서 지우고 테이블 뷰에서도 지운다.
        Feedback.success()
        guard let detailVC = detail2ViewController,
            let indexPathsForSelectedRows = detailVC.tableView.indexPathsForSelectedRows?.sorted(by: { (left, right) -> Bool in
                return left.row > right.row
            }) else { return }
        
        indexPathsForSelectedRows.forEach {
            detailVC.dataSource[$0.section].remove(at: $0.row)
        }
        
        detailVC.tableView.deleteRows(at: indexPathsForSelectedRows, with: .automatic)
        detailVC.transparentNavigationController?.show(message: "✨선택된 영역이 삭제되었습니다✨".loc, color: Color.red)
        detailVC.state = .normal
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
        guard let detailVC = detail2ViewController else { return }
        detailVC.tableView.visibleCells.forEach {
            if let blockCell = $0 as? BlockCell, blockCell.textView.isFirstResponder {
                blockCell.textView.paste(nil)
                detailVC.hasEdit = true
                detailVC.transparentNavigationController?.show(message: "⚡️붙여넣기 완료⚡️".loc)
            }
        }
    }
    
    @IBAction func tapCopyAt(_ sender: Any) {
        guard let detailVC = detail2ViewController else { return }
        detailVC.tableView.visibleCells.forEach {
            if let blockCell = $0 as? BlockCell,
                let textView = blockCell.textView,
                textView.isFirstResponder,
                textView.selectedRange.length != 0 {
                let text = (textView.text as NSString).substring(with: textView.selectedRange)
                UIPasteboard.general.string = text
                textView.selectedRange = NSMakeRange(textView.selectedRange.upperBound, 0)
                detailVC.transparentNavigationController?.show(message: "⚡️선택영역 복사 완료⚡️".loc)
            }
        }
    }
    
    @IBAction func tapCutAt(_ sender: Any) {
        guard let detailVC = detail2ViewController else { return }
        detailVC.tableView.visibleCells.forEach {
            if let blockCell = $0 as? BlockCell,
                let textView = blockCell.textView,
                textView.isFirstResponder,
                textView.selectedRange.length != 0 {
                let text = (textView.text as NSString).substring(with: textView.selectedRange)
                UIPasteboard.general.string = text
                textView.replaceCharacters(in: textView.selectedRange, with: NSAttributedString(string: "", attributes: FormAttribute.defaultAttr))
                detailVC.transparentNavigationController?.show(message: "⚡️선택영역 오려내기 완료⚡️".loc)
            }
        }
    }
    
    @IBAction func tapDone(_ sender: Any) {
        Feedback.success()
        detail2ViewController?.view.endEditing(true)
    }
    
    private func removeHighlight(){
//        guard let textView = textView, let attrText = textView.attributedText else { return }
//        var highlightedRanges: [NSRange] = []
//        attrText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, attrText.length), options: .reverse) { (value, range, _) in
//            guard let color = value as? Color, color == Color.highlight else { return }
//            highlightedRanges.append(range)
//        }
//
//        highlightedRanges.forEach {
//            textView.textStorage.addAttributes([.backgroundColor : Color.clear], range: $0)
//        }
    }
    
    private func rangesForHighlightedText() -> [NSRange] {
//        guard let attrText = textView?.attributedText else { return []}
//        var highlightedRanges: [NSRange] = []
//        attrText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, attrText.length), options: .reverse) { (value, range, _) in
//            guard let color = value as? Color, color == Color.highlight else { return }
//            highlightedRanges.insert(range, at: 0)
//        }
//        return highlightedRanges
        return []
    }

}
