//
//  DetailTitleView.swift
//  Piano
//
//  Created by Kevin Kim on 13/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CloudKit

class DetailTitleView: UIView {
    @IBOutlet weak var label: UILabel!
    
    internal func set(note: Note) {
        
        if let date = note.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from: date)
            label.text = string
        }
        
        discoverUserIdentity(note: note)
    }
    
    private func discoverUserIdentity(note: Note) {
        guard note.isShared,
            let id = note.modifiedBy as? CKRecord.ID else { return }
        
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) {
            userIdentity, error in
            if let nameComponent = userIdentity?.nameComponents {
                let name = (nameComponent.givenName ?? "")
                if let date = note.modifiedAt, !name.isEmpty {
                    let string = DateFormatter.sharedInstance.string(from:date)
                    DispatchQueue.main.async { [weak self] in
                        self?.label.text = string + "\nLatest modified by".loc + "\(name)"
                    }
                }
            }
        }
    }
    
    

}
