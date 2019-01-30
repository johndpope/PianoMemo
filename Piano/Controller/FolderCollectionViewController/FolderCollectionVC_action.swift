//
//  FolderCollectionVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

extension FolderCollectionViewController {
    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapEdit(_ sender: Any) {

    }

    @IBAction func tapNewFolder(_ sender: Any) {
        present(alertController, animated: true)
    }

    @objc func alertInputDidChange(_ sender: Any) {
        guard let count = alertController.textFields?.first?.text?.count else { return }
        alertController.actions.filter({ $0.title == "생성" }).first?.isEnabled = count > 0
    }
}
