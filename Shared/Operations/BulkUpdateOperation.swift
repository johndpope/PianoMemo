//
//  BulkUpdateOperation.swift
//  Piano
//
//  Created by hoemoon on 21/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class BulkUpdateOperation: AsyncOperation {
    private let context: NSManagedObjectContext
    private let completion: () -> Void
    private let request: NSFetchRequest<Note>

    init(request: NSFetchRequest<Note>,
         context: NSManagedObjectContext,
         completion: @escaping () -> Void) {

        self.request = request
        self.context = context
        self.completion = completion
        super.init()
    }

    override func main() {
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                let results = try self.context.fetch(self.request)
                for result in results {
                    let note = try self.context.existingObject(with: result.objectID) as? Note
                    switch note {
                    case .some(let note):
                        if let paragraphs = note.content?.components(separatedBy: .newlines) {
                            let convertedParagraphs = paragraphs.map { (paragraph) -> String in

                                for (index, oldKeyOff) in PianoBullet.oldKeyOffList.enumerated() {
                                    guard let (_, range) = paragraph.detect(searchRange: NSRange(location: 0, length: paragraph.utf16.count), regex: "^\\s*([\(oldKeyOff)])(?= )") else { continue }
                                    return (paragraph as NSString).replacingCharacters(in: range, with: PianoBullet.keyOnList[index])
                                }

                                for (index, oldKeyOn) in PianoBullet.oldKeyOnList.enumerated() {
                                    guard let (_, range) = paragraph.detect(searchRange: NSRange(location: 0, length: paragraph.utf16.count), regex: "^\\s*([\(oldKeyOn)])(?= )") else { continue }
                                    return (paragraph as NSString).replacingCharacters(in: range, with: PianoBullet.keyOffList[index])
                                }
                                return paragraph
                            }

                            var contents = convertedParagraphs.joined(separator: "\n")
                            contents = contents.replacingOccurrences(of: "✵", with: "✷")
                            contents = contents.replacingOccurrences(of: "✸", with: "✷")
                            contents = contents.replacingOccurrences(of: "✹", with: "✷")
                            contents = contents.replacingOccurrences(of: "✺", with: "✷")
                            contents = contents.replacingOccurrences(of: "♪", with: "♩")
                            contents = contents.replacingOccurrences(of: "♫", with: "♩")
                            contents = contents.replacingOccurrences(of: "♬", with: "♩")
                            contents = contents.replacingOccurrences(of: "♭", with: "♩")

                            note.content = contents

                        }
                    case .none:
                        break
                    }
                }
                self.context.saveOrRollback()
                self.completion()
                self.state = .Finished
            } catch {
                print(error)
                self.completion()
                self.state = .Finished
            }
        }
    }
}
