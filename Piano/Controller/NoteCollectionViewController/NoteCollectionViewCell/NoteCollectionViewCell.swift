//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 06/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var folderLabel: UILabel!
    @IBOutlet weak var writeNowButton: UIButton!
    weak var noteCollectionVC: NoteCollectionViewController?
    @IBOutlet weak var overlayTitle: UILabel!
    @IBOutlet weak var overlayView: UIView!

    lazy var blurEffectView: UIView = {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurEffectView
    }()

    func setup(note: Note?) {
        guard let note = note else { return }
        if titleLabel.attributedText != nil {
            titleLabel.attributedText = nil
        }
        if subTitleLabel.attributedText != nil {
            subTitleLabel.attributedText = nil
        }
        titleLabel.text = note.title
        subTitleLabel.text = note.subTitle
        commonSetup(note: note)
    }

    func setup(note: Note?, keyword: String?) {
        guard let note = note, let keyword = keyword else { return }
        if let title = highlight(note: note, keyword: keyword).0 {
            titleLabel.attributedText = title
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = note.title
        }
        if let subtitle = highlight(note: note, keyword: keyword).1 {
            subTitleLabel.attributedText = subtitle
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = note.title
        }
        commonSetup(note: note)
    }

    private func commonSetup(note: Note) {
        guard let vc = noteCollectionVC else { return }
        let tags = note.tags?.count != 0 ? note.tags : ""
        folderLabel.text = tags

        if note.isLocked {
            overlayView.insertSubview(blurEffectView, at: 0)
            overlayTitle.text = note.title
            overlayView.isHidden = false
        } else {
            overlayView.isHidden = true
        }

        if let expireDate = note.expireDate {
            dateLabel.textColor = Color.red
            let str = expireDate.dDayStr(sinceDate: Date())
            dateLabel.text = "폭파 시간: \(str)"
        } else {
            dateLabel.textColor = Color.lightGray
            let date = note.modifiedAt as Date? ?? Date()
            dateLabel.text = DateFormatter.sharedInstance.string(from: date)
        }
        writeNowButton.isHidden = ((note.content?.count ?? 0) < 500) || vc.isEditing
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
    }
}

extension NoteCollectionViewCell {
    private func highlight(note: Note, keyword: String) -> (NSAttributedString?, NSAttributedString?) {
        return (highlight(text: note.title, keyword: keyword), highlight(text: note.content ?? "", keyword: keyword))
    }

    private func highlight(text: String, keyword: String) -> NSAttributedString? {
        guard keyword.count > 0 else { return nil }
        let keyword = keyword.lowercased()
        if let keywordRange = text.lowercased().range(of: keyword) {
            let start = text.startIndex
            let beforeText = text[start..<keywordRange.lowerBound]
            var afterText = String(text[keywordRange.lowerBound..<text.endIndex])
                .replacingOccurrences(of: "\n", with: " ")

            let components = beforeText
                .replacingOccurrences(of: "\n", with: " ")
                .components(separatedBy: " ")
                .filter { $0 != "" }

            if var lastword = components.last, lastword.count > 10 {
                let index = lastword.index(lastword.endIndex, offsetBy: -10)
                lastword = String(lastword.suffix(from: index))
                afterText.insert(contentsOf: "..." + lastword + " ", at: afterText.startIndex)
            } else if let lastword = components.last, lastword.count <= 10 {
                afterText.insert(contentsOf: lastword, at: afterText.startIndex)
            }

            if let highlightRange = afterText.lowercased().range(of: keyword) {
                let attributed = NSMutableAttributedString(string: afterText)
                attributed.addAttributes(
                    [NSAttributedString.Key.foregroundColor: UIColor(red: 0.90, green: 0.69, blue: 0.03, alpha: 1.00)],
                    range: NSRange(highlightRange, in: afterText)
                )
                return attributed
            }
        }
        return nil
    }
}
