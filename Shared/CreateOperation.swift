//
//  CreateOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

protocol RecordProvider{
    var recordsToSave: Array<CKRecord>? { get }
    var recordsToDelete: Array<CKRecord>? { get }
}

class CreateOperation: Operation, RecordProvider {
    var attributedString: NSAttributedString
    weak var context: NSManagedObjectContext?

    var recordsToSave: Array<CKRecord>?
    var recordsToDelete: Array<CKRecord>?

    init(attributedString: NSAttributedString,
         context: NSManagedObjectContext) {
        self.attributedString = attributedString
        self.context = context
        super.init()
    }

    override func main() {
        guard let context = context else { return }
        context.performAndWait {
            let note = Note(context: context)
            let string = attributedString.deformatted
            let (title, subTitle) = string.titles
            note.title = title
            note.subTitle = subTitle
            note.createdAt = Date()
            note.modifiedAt = Date()
            note.content = string
            recordsToSave = [note.recodify()]
        }

        do {
            try context.save()
        } catch {
            print(error)
        }
        print(#function)
    }
}


private extension String {
    var titles: (String, String) {
        var strArray = self.split(separator: "\n")
        guard strArray.count != 0 else {
            return ("Untitled".loc, "No text".loc)
        }
        let titleSubstring = strArray.removeFirst()
        var titleString = String(titleSubstring)
        titleString.removeCharacters(strings: Preference.allKeys)
        let titleLimit = 50
        if titleString.count > titleLimit {
            titleString = (titleString as NSString).substring(with: NSMakeRange(0, titleLimit))
        }


        var subTitleString: String = ""
        while true {
            guard strArray.count != 0 else { break }

            let pieceSubString = strArray.removeFirst()
            var pieceString = String(pieceSubString)
            pieceString.removeCharacters(strings: Preference.allKeys)
            subTitleString.append(pieceString)
            let titleLimit = 50
            if subTitleString.count > titleLimit {
                subTitleString = (subTitleString as NSString).substring(with: NSMakeRange(0, titleLimit))
                break
            }
        }

        return (titleString, subTitleString.count != 0 ? subTitleString : "No text".loc)    }
}
