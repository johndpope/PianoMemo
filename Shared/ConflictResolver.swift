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
        var oldArray = old.map { $0 }
        let newArray = new.map { $0 }
        let diff2 = oldArray.diff(newArray)
        let patch2 = diff2.patch(from: oldArray, to: newArray)

        for change in patch2 {
            switch change {
            case .insertion(let index, let element):
                let target = oldArray.index(oldArray.startIndex, offsetBy: index)
                oldArray.insert(element, at: target)
            case .deletion(_):
                continue
            }
        }

        return oldArray.map { String($0) }.joined()
    }

    func positiveMerge(old: NSAttributedString, new: String) -> NSAttributedString {
        let mutableOld = NSMutableAttributedString(string: old.string, attributes: Preference.defaultAttr)
        let oldArray = old.string.map { $0 }
        let newArray = new.map { $0 }
        let diff = oldArray.diff(newArray)
        let patch = diff.patch(from: oldArray, to: newArray)

        for (patchIndex, change) in patch.enumerated() {
            switch change {
            case .insertion(let index, let element):
                let mutableString = mutableOld.string
                let target = mutableString.index(mutableString.startIndex, offsetBy: index)
                    .encodedOffset
                var attribues = Preference.defaultAttr
                let string = String(element)
                if patchIndex == 0, !string.isValid {
                    //  attribues[.animatingBackground] = false
                } else if patchIndex == patch.count - 1, !string.isValid {
                    //  attribues[.animatingBackground] = false
                } else {
                    attribues[.animatingBackground] = true
                }
                let attributed = NSAttributedString(
                    string: string,
                    attributes: attribues
                )
                mutableOld.insert(attributed, at: target)
            case .deletion(_):
                continue
            }
        }
        return mutableOld
    }
}

private extension String {
    var isValid: Bool {
        return self.trimmingCharacters(in: .whitespaces).count > 0
    }
}
