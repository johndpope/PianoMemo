//
//  PDFConvertViewController.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PDFConvertViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    internal var note: Note!
    private var collectionables: [[Collectionable]] = []
    private var cache: [IndexPath: (fontType: FontType?, attrType: AttributeType?)] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let fullText = note.content else {return }
        collectionables.append(fullText.components(separatedBy: .newlines))
        
    }

    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PDFConvertViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return collectionables.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionables[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let str = collectionables[indexPath.section][indexPath.row] as! String
        var cell = tableView.dequeueReusableCell(withIdentifier: "ParagraphCell") as! UITableViewCell & ViewModelAcceptable
        
        let fontType = cache[indexPath]?.fontType
        let attrType = cache[indexPath]?.attrType
        let viewModel = ParagraphViewModel(str: str, viewController: self, fontType: fontType, attrType: attrType)
        cell.viewModel = viewModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3) ?? UITableViewCell.EditingStyle.none
    }
    
    private func setCacheBy(indexPath: IndexPath, fontType: FontType) {
        tableView.performBatchUpdates({
            if var mutableCache = cache[indexPath] {
                
                if let existFontType = mutableCache.fontType, existFontType == fontType {
                    mutableCache.fontType = FontType.body
                } else {
                    mutableCache.fontType = fontType
                }
                cache[indexPath] = mutableCache
                
            } else {
                cache[indexPath] = (fontType, nil)
            }
            
            guard var cell = tableView.cellForRow(at: indexPath) as? ViewModelAcceptable else { return }
            let str = collectionables[indexPath.section][indexPath.row] as! String
            let viewModel = ParagraphViewModel(str: str, viewController: self, fontType: cache[indexPath]?.fontType, attrType: nil)
            cell.viewModel = viewModel
            
        }, completion: nil)
        
    }
    
    private func setCacheBy(indexPath: IndexPath, attrType: AttributeType) {
        tableView.performBatchUpdates({
            if var mutableCache = cache[indexPath] {
                if let existAttrType = mutableCache.attrType, existAttrType == attrType {
                    mutableCache.attrType = AttributeType.body(Font.preferredFont(forTextStyle: .body))
                } else {
                    mutableCache.attrType = attrType
                }
                cache[indexPath] = mutableCache
            } else {
                cache[indexPath] = (nil, attrType)
            }
            
            guard var cell = tableView.cellForRow(at: indexPath) as? ViewModelAcceptable else { return }
            let str = collectionables[indexPath.section][indexPath.row] as! String
            let viewModel = ParagraphViewModel(str: str, viewController: self, fontType: nil, attrType: cache[indexPath]?.attrType)
            cell.viewModel = viewModel
            
        }, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let largeTitle: FontType = .largeTitle
        let title1Action = UIContextualAction(style: .normal, title:  largeTitle.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, fontType: largeTitle)
            
        })
        //        title1Action.image
        title1Action.backgroundColor = UIColor(red: 255/255, green: 158/255, blue: 78/255, alpha: 1)
        
        let title1: FontType = .title1
        let title2Action = UIContextualAction(style: .normal, title:  title1.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, fontType: title1)
            
            
        })
        //        title1Action.image
        title2Action.backgroundColor = UIColor(red: 253/255, green: 170/255, blue: 86/255, alpha: 1)
        
        let title2: FontType = .title2
        let title3Action = UIContextualAction(style: .normal, title:  title2.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, fontType: title2)
        })
        //        title1Action.image
        title3Action.backgroundColor = UIColor(red: 200/255, green: 150/255, blue: 86/255, alpha: 1)
        return UISwipeActionsConfiguration(actions: [title1Action, title2Action, title3Action])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //인덱스 패스에 캐시가 있다면 해당 폰트를 쓰기 없으면 바디
        
        let font = cache[indexPath]?.fontType?.font ?? UIFont.preferredFont(forTextStyle: .body)
        
        let black: AttributeType = .black(font)
        let blackAction = UIContextualAction(style: .normal, title:  black.string, handler: { [weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            
            success(true)
            self.setCacheBy(indexPath: indexPath, attrType: black)
        })
        //        closeAction.image = UIImage(named: "tick")
        let blueColor = UIColor(red: 59/255, green: 141/255, blue: 251/255, alpha: 1)
        blackAction.backgroundColor = blueColor
        
        let medium: AttributeType = .medium(font)
        let mediumAction = UIContextualAction(style: .normal, title:  medium.string, handler: { [weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, attrType: medium)
        })
        //        closeAction.image = UIImage(named: "tick")
        let greenColor = UIColor(red: 20/255, green: 15/255, blue: 221/255, alpha: 1)
        mediumAction.backgroundColor = greenColor
        
        
        let thin: AttributeType = .thin(font)
        let thinAction = UIContextualAction(style: .normal, title:  thin.string, handler: { [weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, attrType: thin)
        })
        //        closeAction.image = UIImage(named: "tick")
        let yellowColor = UIColor(red: 200/255, green: 70/255, blue: 100/255, alpha: 1)
        thinAction.backgroundColor = yellowColor
        
        return UISwipeActionsConfiguration(actions: [thinAction, mediumAction, blackAction])
    }
}

extension PDFConvertViewController: UITableViewDelegate {
    
}

extension NSAttributedString {
    var font: Font? {
        var font: Font?
        enumerateAttribute(.font, in: NSMakeRange(0, length), options: .reverse) { (value, _, stop) in
            guard let fontValue = value as? Font else { return }
            font = fontValue
            stop.pointee = true
        }
        return font
    }
}
