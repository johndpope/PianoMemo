//
//  NoteCell.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct NoteViewModel: ViewModel {
    let note: Note
    let viewController: ViewController?
    var highlightedTitle: NSAttributedString?
    var highlightedSubTitle: NSAttributedString?
    
    init(note: Note,
         searchKeyword: String = "",
         viewController: ViewController? = nil) {
        self.note = note
        self.viewController = viewController
        guard searchKeyword.count != 0 else {
            highlightedTitle = nil
            highlightedSubTitle = nil
            return
        }
        if let title = note.title {
            highlightedTitle = highlight(text: title, keyword: searchKeyword)
        }

        if let content = note.content {
            highlightedSubTitle = highlight(text: content, keyword: searchKeyword)
        }
    }

    private func highlight(text: String, keyword: String) -> NSAttributedString? {
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

            if components.count > 0 {
                afterText.insert(contentsOf: "..." + components.last! + " ", at: afterText.startIndex)
            }

            if let highlightRange = afterText.lowercased().range(of: keyword) {
                let attributed = NSMutableAttributedString(string: afterText)
                attributed.addAttributes(
                    [NSAttributedString.Key.foregroundColor : UIColor(red:0.90, green:0.69, blue:0.03, alpha:1.00)],
                    range: NSRange(highlightRange, in: afterText)
                )
                return attributed
            }
        }
        return nil
    }
}

class NoteCell: UITableViewCell, ViewModelAcceptable {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    
    var viewModel: ViewModel? {
        didSet {
            backgroundColor = Color.white
            guard let noteViewModel = self.viewModel as? NoteViewModel else { return }
            let note = noteViewModel.note
            
            if let date = note.modifiedAt {
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                if Calendar.current.isDateInToday(date) {
                    dateLabel.textColor = Color.point
                } else {
                    dateLabel.textColor = Color.lightGray
                }
            }

            if let attributedTitle = noteViewModel.highlightedTitle {
                titleLabel.attributedText = attributedTitle
            } else {
                titleLabel.text = note.title
            }

            if let attrbutedSubTitle = noteViewModel.highlightedSubTitle, !note.isLocked {
                subTitleLabel.attributedText = attrbutedSubTitle
            } else {
                subTitleLabel.text = !note.isLocked ? note.subTitle : "Locked🔒".loc
            }
            
            let shareText = note.isShared ? Preference.shareStr : ""
            tagsLabel.text = (note.tags ?? "") + shareText
            
            
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
//        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        //        view.cornerRadius = 15
        return view
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        subTitleLabel.attributedText = nil
    }
}

extension Note: Collectionable {
}
