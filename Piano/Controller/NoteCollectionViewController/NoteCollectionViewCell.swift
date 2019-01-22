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
    @IBOutlet weak var moreButton: UIButton!

    var note: Note? {
        didSet {
            guard let note = note else { return }
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            let tags = note.tags?.count != 0 ? note.tags : "😁"
            folderLabel.text = tags
            let date = note.modifiedAt as Date? ?? Date()
            dateLabel.text = DateFormatter.sharedInstance.string(from: date)
        }
    }
    weak var noteCollectionVC: NoteCollectionViewController?

    lazy var customSelectedBackgroudView: UIView = {
        let view = UIView()
        view.backgroundColor = Color(red: 153/255, green: 199/255, blue: 255/255, alpha: 0.3)
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(tapLongPress(_:)))
        self.addGestureRecognizer(longPress)

    }

    @IBAction func tapLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard let vc = noteCollectionVC else { return }
            let editing = vc.isEditing
            noteCollectionVC?.setEditing(!editing, animated: true)
        }
    }

    @IBAction func tapMoreBtn(_ sender: Any) {
        //TODO: 액션 시트 만들어서 삭제, 잠금, 이동, 고정, 위젯으로 등록

        let alertController = AlertController(title: "Edit".loc, message: nil, preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: "Delete".loc, style: .destructive) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let note = self.note else {
                    print("tapMoreBtn에서 deleteAction시, self, note 혹은 vc가 nil임")
                    return
            }
            vc.noteHandler.remove(notes: [note], completion: { (bool) in
                if bool {
                    let message = "Note are deleted.".loc
                    vc.transparentNavigationController?.show(message: message, color: Color.redNoti)
                }
            })
        }

        let lockAction = UIAlertAction(title: "Lock".loc, style: .default) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let note = self.note else {
                print("tapMoreBtn에서 lockAction시, self, note 혹은 vc가 nil임")
                return
            }

            vc.noteHandler.lockNote(notes: [note], completion: { (bool) in
                if bool {
                    vc.transparentNavigationController?.show(message: "Locked🔒".loc, color: Color.goldNoti)
                }
            })

        }

        let moveAction = UIAlertAction(title: "Move".loc, style: .default) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let note = self.note else {
                print("tapMoreBtn에서 moveAction시, self, note 혹은 vc가 nil임")
                return
            }
            //TODO: move api 나오면 적기

        }

        let pinAction = UIAlertAction(title: "Pin".loc, style: .default) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let note = self.note else {
                    print("tapMoreBtn에서 pinAction시, self, note 혹은 vc가 nil임")
                    return
            }
            vc.noteHandler.pinNote(notes: [note], completion: { (bool) in
                if bool {
                    //TODO: note를 고정했을 때 메시지 작성하기
//                    vc.transparentNavigationController?.show(message: <#T##String#>, textColor: <#T##Color?#>, color: <#T##Color?#>)
                }
            })
        }

        let widgetAction = UIAlertAction(title: "Widget".loc, style: .default) { (_) in
            //TODO: note를 widget에 등록하자
        }

        let cancelAction = UIAlertAction(title: "Cancel".loc, style: .cancel) { (_) in
        }

        alertController.addAction(widgetAction)
        alertController.addAction(pinAction)
        alertController.addAction(moveAction)
        alertController.addAction(lockAction)
        alertController.addAction(deleteAction)

        alertController.addAction(cancelAction)

        noteCollectionVC?.present(alertController, animated: true, completion: nil)

    }

}
