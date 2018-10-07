//
//  PianoEditorViewController.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PianoEditorViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    internal var note: Note!
    private var collectionables: [[Collectionable]] = []
    private var cache: [IndexPath : ParagraphTextType] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let fullText = note.content else {return }
        collectionables.append(fullText.components(separatedBy: .newlines))
        
    }

    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PianoEditorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return collectionables.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionables[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "ParagraphCell") as! UITableViewCell & ViewModelAcceptable

        let str = collectionables[indexPath.section][indexPath.row] as! String
        let viewModel = ParagraphViewModel(str: str, viewController: self, paraType: cache[indexPath])
        cell.viewModel = viewModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let str = collectionables[indexPath.section][indexPath.row] as! String
        return str.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3) ?? UITableViewCell.EditingStyle.none
    }
    
    private func setCacheBy(indexPath: IndexPath, paraType: ParagraphTextType) {
        tableView.performBatchUpdates({
            if let cacheParaType = cache[indexPath], cacheParaType == paraType {
                //캐시 초기화시키기
                cache[indexPath] = nil
            } else {
                //캐시에 대입
                cache[indexPath] = paraType
            }
                
            //UI Update
            guard var cell = tableView.cellForRow(at: indexPath) as? ViewModelAcceptable else { return }
            let str = collectionables[indexPath.section][indexPath.row] as! String
            let viewModel = ParagraphViewModel(str: str, viewController: self, paraType: cache[indexPath])
            cell.viewModel = viewModel
            
        }, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title: ParagraphTextType = .title
        let titleAction = UIContextualAction(style: .normal, title:  title.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, paraType: title)
            
        })
        //        title1Action.image
        titleAction.backgroundColor = UIColor(red: 255/255, green: 158/255, blue: 78/255, alpha: 1)
        
        let subTitle: ParagraphTextType = .subTitle
        let subTitleAction = UIContextualAction(style: .normal, title:  subTitle.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, paraType: subTitle)
            
        })
        //        title1Action.image
        subTitleAction.backgroundColor = UIColor(red: 253/255, green: 170/255, blue: 86/255, alpha: 1)
        
        
        return UISwipeActionsConfiguration(actions: [titleAction, subTitleAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let accent: ParagraphTextType = .accent
        let accentAction = UIContextualAction(style: .normal, title:  accent.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, paraType: accent)
        })
        //        title1Action.image
        accentAction.backgroundColor = UIColor(red: 255/255, green: 158/255, blue: 78/255, alpha: 1)
        
        let ref: ParagraphTextType = .ref
        let refAction = UIContextualAction(style: .normal, title:  ref.string, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            self.setCacheBy(indexPath: indexPath, paraType: ref)
        })
        //        title1Action.image
        refAction.backgroundColor = UIColor(red: 253/255, green: 170/255, blue: 86/255, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [refAction, accentAction])
    }
}

extension PianoEditorViewController: UITableViewDelegate {
    
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
