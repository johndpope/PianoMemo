//
//  CNContactVC_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import ContactsUI
import Foundation

extension CNContactViewController {
    internal func setCancel() {
        let btn = BarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.setLeftBarButtonItems([btn], animated: true)
    }
    
    @objc func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
