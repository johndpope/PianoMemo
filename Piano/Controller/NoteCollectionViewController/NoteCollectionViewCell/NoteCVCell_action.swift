//
//  NoteCVCell_action.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewCell {
    @IBAction func tapLongPress(_ sender: LongPressGestureRecognizer) {
        if sender.state == .began {
            guard let vc = noteCollectionVC else { return }
            let editing = vc.isEditing
            noteCollectionVC?.setEditing(!editing, animated: true)
        }
    }

    @IBAction func tapMoreBtn(_ sender: Any) {
        //TODO: 액션 시트 만들어서 삭제, 잠금, 이동, 고정, 위젯으로 등록

        let alertController = AlertController(title: "Edit".loc, message: nil, preferredStyle: .actionSheet)

        let deleteAction = AlertAction(title: "Delete".loc, style: .destructive) { [weak self](_) in
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

        let lockAction = AlertAction(title: "Lock".loc, style: .default) { [weak self](_) in
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

        let moveAction = AlertAction(title: "Move".loc, style: .default) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let note = self.note else {
                    print("tapMoreBtn에서 moveAction시, self, note 혹은 vc가 nil임")
                    return
            }
            //TODO: move api 나오면 적기

        }

        let pinAction = AlertAction(title: "Pin".loc, style: .default) { [weak self](_) in
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

        let expireAction = AlertAction(title: "Expire Date", style: .destructive) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let note = self.note else {
                print("tapMoreBtn에서 expireAction시, self, note 혹은 vc가 nil임")
                return
            }
            vc.performSegue(withIdentifier: ExpireDateViewController.identifier, sender: note)
        }

        let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel) { (_) in
        }

        alertController.addAction(pinAction)
        alertController.addAction(moveAction)
        alertController.addAction(lockAction)
        alertController.addAction(expireAction)
        alertController.addAction(deleteAction)

        alertController.addAction(cancelAction)

        noteCollectionVC?.present(alertController, animated: true, completion: nil)

    }

}
