//
//  NoteCVCell_action.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewCell {

    /// TODO:
    ///     - 액션 시트 만들어서 삭제, 잠금, 이동, 고정, 위젯으로 등록
    ///     - 반복적으로 요청하는 auth request 더 간단하게 할 수 없을지 고민
    @IBAction func tapMoreBtn(_ sender: Any) {

        let alertController = AlertController(title: "Edit".loc, message: nil, preferredStyle: .actionSheet)

        let lockAction = AlertAction(title: "Lock".loc, style: .default) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let noteHandler = vc.noteHandler,
                let note = self.note else {
                    print("tapMoreBtn에서 lockAction시, self, note 혹은 vc가 nil임")
                    return
            }
            
            noteHandler.lockNote(notes: [note], completion: { (bool) in
                if bool {
                    vc.transparentNavigationController?.show(message: "Locked🔒".loc, color: Color.goldNoti)
                }
            })

        }
        
        let unlockAction = AlertAction(title: "Unlock".loc, style: .destructive) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let noteHandler = vc.noteHandler,
                let note = self.note else {
                    return
            }
            
            func unlock() {
                noteHandler.unlockNote(notes: [note], completion: { (bool) in
                    if bool {
                        vc.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc, color: Color.goldNoti)
                    }
                })
            }
            
            let reason = "Unlock note".loc
            Authenticator.requestAuth(reason: reason, success: {
                unlock()
            }, failure: { error in
                
            }, notSet: {
                unlock()
            })
        }
        
        let deleteAction = AlertAction(title: "Delete".loc, style: .destructive) { [weak self](_) in
            guard let self = self,
                let vc = self.noteCollectionVC,
                let noteHandler = vc.noteHandler,
                let note = self.note else {
                    print("tapMoreBtn에서 deleteAction시, self, note 혹은 vc가 nil임")
                    return
            }
            
            func delete() {
                noteHandler.remove(notes: [note], completion: { (bool) in
                    if bool {
                        let message = "Note are deleted.".loc
                        vc.transparentNavigationController?.show(message: message, color: Color.redNoti)
                    }
                })
            }
            
            let reason = "Delete locked note".loc
            Authenticator.requestAuth(reason: reason, success: {
                delete()
            }, failure: { error in
                
            }, notSet: {
                delete()
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
                let noteHandler = vc.noteHandler,
                let note = self.note else {
                    print("tapMoreBtn에서 pinAction시, self, note 혹은 vc가 nil임")
                    return
            }
            noteHandler.pinNote(notes: [note], completion: { (bool) in
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
            
            let reason = "Delete locked note".loc
            Authenticator.requestAuth(reason: reason, success: {
                vc.performSegue(withIdentifier: ExpireDateViewController.identifier, sender: note)
            }, failure: { error in
                
            }, notSet: {
                vc.performSegue(withIdentifier: ExpireDateViewController.identifier, sender: note)
            })
        }

        let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel) { (_) in
        }

        alertController.addAction(pinAction)
        alertController.addAction(moveAction)
        if let locked = note?.isLocked, locked {
            alertController.addAction(unlockAction)
        } else {
            alertController.addAction(lockAction)
        }
        alertController.addAction(expireAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        noteCollectionVC?.present(alertController, animated: true, completion: nil)

    }

}
