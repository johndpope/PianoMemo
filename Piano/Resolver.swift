//
//  Merge.swift
//  Piano
//
//  Created by hoemoon on 11/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

typealias ResolveResult = (Bool, String)

struct Resolver {
    static func merge(base: String, mine: String, their: String) -> String {
        var offset = 0
        var hasConflict = false
        let mutableMine = NSMutableString(string: mine)

        let diff3Maker = Diff3Maker(ancestor: base, a: mine, b: their)
        let diff3Chunks = diff3Maker.mergeInLineLevel().flatMap { chunk -> [Diff3Block] in
            if case let .change(oRange, aRange, bRange) = chunk {
                let oString = (base as NSString).substring(with: oRange)
                let aString = (mine as NSString).substring(with: aRange)
                let bString = (their as NSString).substring(with: bRange)

                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)

            } else if case let .conflict(oRange, aRange, bRange) = chunk {
                let oString = (base as NSString).substring(with: oRange)
                let aString = (mine as NSString).substring(with: aRange)
                let bString = (their as NSString).substring(with: bRange)
                hasConflict = true

                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
            } else {
                return [chunk]
            }
        }

        if hasConflict {
            let mineSet = Set(mine.map { $0 })
            let theirSet = Set(their.map { $0 })
            if mineSet.isSubset(of: theirSet) {
                return their
            }
        }

        diff3Chunks.forEach {
            switch $0 {
            case .add(let index, let range):
                let replacement = NSMutableString(string: their).substring(with: range)
                mutableMine.insert(replacement, at: index+offset)
                offset += range.length
            case .delete(let range):
                mutableMine.deleteCharacters(in: NSMakeRange(range.location + offset, range.length))
                offset -= range.length
            case .change(_, let myRange, let serverRange):
                let replacement = (their as NSString).substring(with: serverRange)
                mutableMine.replaceCharacters(in: NSMakeRange(myRange.location + offset, myRange.length), with: replacement)
                offset += serverRange.length - myRange.length
            default: break
            }
        }

        return mutableMine as String
    }

    static func merge(ancestor: CKRecord, client: CKRecord, server: CKRecord) -> CKRecord {
        let key = RemoteStorageSerevice.NoteFields.content
        if let base = ancestor[key] as? String,
            let mine = client[key] as? String,
            let their = server[key] as? String {
            let merged = merge(base: base, mine: mine, their: their)
            client[key] = merged as CKRecordValue
        }
        return client
    }
}
