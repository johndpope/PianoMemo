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
        if let id = note.modifiedBy as? CKRecord.ID, note.isShared {
            CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self]
                userIdentity, error in
                guard let self = self else { return }
                if let name = userIdentity?.nameComponents?.givenName, !name.isEmpty {
                    let str = self.dateAndTagStr(from: note)
                    DispatchQueue.main.async {
                        self.label.text = str + ", Latest modified by".loc + name
                    }
                }
            }
        } else {
            label.text = dateAndTagStr(from: note)
        }
    }
    
    private func dateAndTagStr(from note: Note) -> String {
        var fullStr = ""
        
        if let date = note.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from: date)
            fullStr.append(string)
        }
        
        if let tags = note.tags, tags.count != 0 {
            fullStr.append("\n" + tags)
        }
        
        return fullStr
    }

}
