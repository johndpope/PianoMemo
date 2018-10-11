//
//  NoteTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct NoteViewModel: ViewModel {
    let note: Note
    let viewController: ViewController?
    
    init(note: Note, viewController: ViewController? = nil) {
        self.note = note
        self.viewController = viewController
    }
}

class NoteCell: UITableViewCell, ViewModelAcceptable {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var shareLabel: UILabel!
    
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
            
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            shareLabel.isHidden = !note.isShared
            
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
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

}

extension Note: Collectionable {
}
