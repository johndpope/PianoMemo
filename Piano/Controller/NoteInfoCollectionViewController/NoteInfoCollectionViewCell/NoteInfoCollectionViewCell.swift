//
//  NoteInfoCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteInfoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    var data: NoteInfoCollectionViewController.NoteInfo? {
        get {
            //참조할 일이 없어서 nil로 해둠
            return nil
        } set {
            guard let noteInfo = newValue,
                let content = noteInfo.note.content else { return }
            let note = noteInfo.note
            switch noteInfo.type {
            case .creationDate:
                titleLabel.text = "Creation Date".loc
                let creationDate = note.createdAt ?? Date()
                subTitleLabel.text = DateFormatter.sharedInstance.string(from: creationDate)
                
            case .modifiedDate:
                titleLabel.text = "Mofidied Date".loc
                let modifiedDate = note.modifiedAt ?? Date()
                subTitleLabel.text = DateFormatter.sharedInstance.string(from: modifiedDate)
                
            case .characterCount:
                titleLabel.text = "Character count".loc
                subTitleLabel.text = "\(content.count)"
                
            case .paragraphCount:
                titleLabel.text = "Paragraph count".loc
                //느릴 수 있는 작업에 대한 비동기 처리
                DispatchQueue.global().async {
                    let paragraphCount = content.components(separatedBy: .newlines).count
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.subTitleLabel.text = "\(paragraphCount)"
                    }
                }
                
            case .checklistCount:
                titleLabel.text = "Checklist count".loc
                DispatchQueue.global().async {
                    let paragraphs = content.components(separatedBy: .newlines)
                    let checklists = paragraphs.compactMap { (paragraph) -> PianoBullet? in
                        let range = NSRange(location: 0, length: 0)
                        guard let bullet = PianoBullet(type: .key, text: paragraph, selectedRange: range) else { return nil }
                        return bullet
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.subTitleLabel.text = "\(checklists.count)"
                    }
                }
                
            case .checklistAchievementRate:
                titleLabel.text = "Checklist achievement rate".loc
                DispatchQueue.global().async {
                    let paragraphs = content.components(separatedBy: .newlines)
                    let checklists = paragraphs.compactMap { (paragraph) -> PianoBullet? in
                        let range = NSRange(location: 0, length: 0)
                        guard let bullet = PianoBullet(type: .key, text: paragraph, selectedRange: range) else { return nil }
                        return bullet
                    }
                    let checkOnList = checklists.filter { $0.isOn }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        let count = Double(checklists.count)
                        let checkOnListCount = Double(checkOnList.count)
                        if count != 0 {
                            let percent = (checkOnListCount / count) * 100
                            self.subTitleLabel.text = "\(Int(percent))%"
                        } else {
                            self.subTitleLabel.text = "No Checklist".loc
                        }
                    }
                }
                
            case .folder:
                titleLabel.text = "Folder info".loc
                subTitleLabel.text = note.folder?.name ?? "No folder".loc
                
            case .expireDate:
                titleLabel.text = "Expire Date".loc
                if let expireDate = note.expireDate {
                    subTitleLabel.text = DateFormatter.sharedInstance.string(from: expireDate)
                } else {
                    subTitleLabel.text = "n/a".loc
                }
            }
        }
    }
}
