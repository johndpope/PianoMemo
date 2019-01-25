//
//  ExpireDateVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ExpireDateViewController {
    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapDone(_ sender: Any) {
        noteHandler.update(notes: [note], expireDate: datePicker.date) { [weak self] (_) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func tapDelete(_ sender: Any) {
        noteHandler.update(notes: [note], expireDate: nil) { [weak self](_) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
    }
}
