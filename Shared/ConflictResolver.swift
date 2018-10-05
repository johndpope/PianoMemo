//
//  ConflictResolver.swift
//  Piano
//
//  Created by hoemoon on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import Differ

protocol ConflictResolverType {
    func positiveMerge(old: String, new: String) -> String
    func positiveMerge(old: NSAttributedString, new: String) -> NSAttributedString
}

class ConflictResolver: ConflictResolverType {
    func positiveMerge(old: String, new: String) -> String {
        var mutableOld = Array(old.utf16)
        let diff = old.utf16.diff(new.utf16)
        let patch = diff.patch(from: old.utf16, to: new.utf16)

        for change in patch {
            switch change {
            case .insertion(let index, let element):
                let target = mutableOld.index(mutableOld.startIndex, offsetBy: index)
                mutableOld.insert(element, at: target)
            case .deletion(_):
                continue
            }
        }
        return mutableOld.compactMap { UnicodeScalar($0) }
            .map { String($0) }
            .joined()
    }

    func positiveMerge(old: NSAttributedString, new: String) -> NSAttributedString {
        let mutableOld = NSMutableAttributedString(string: old.string)
        let diff = old.string.utf16.diff(new.utf16)
        let patch = diff.patch(from: old.string.utf16, to: new.utf16)

        for change in patch {
            switch change {
            case .insertion(let index, let element):
                let mutableString = mutableOld.string
                let target = mutableString.index(mutableString.startIndex, offsetBy: index)
                    .encodedOffset
                if let scalar = UnicodeScalar(element) {
                    let string = String(scalar)
                    let attributed = NSAttributedString(
                        string: string,
                        attributes: [.animatingBackground : true]
                    )
                    mutableOld.insert(attributed, at: target)
                }
            case .deletion(_):
                continue
            }
        }
        return mutableOld
    }

    private func insertionsFirst(element1: Diff.Element, element2: Diff.Element) -> Bool {
        switch (element1, element2) {
        case (.insert(let at1), .insert(let at2)):
            return at1 < at2
        case (.insert, .delete):
            return true
        case (.delete, .insert):
            return false
        case (.delete(let at1), .delete(let at2)):
            return at1 < at2
        }
    }
}
