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

class BulkUpdateOperation: Operation {
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
        context.performAndWait {
            do {
                let fetched = try context.fetch(request)
                fetched.forEach { note in

                    do {
                        let object = try context.existingObject(with: note.objectID)
                        guard let note = object as? Note else { return }

                        //여기서 유저 디파인 값 초기화해준다.
                        //TODO: 여기서 문단 맨 앞의 올드 키 값들을 새 키 값들로 대체시켜준다.

                        guard let paragraphs = note.content?.components(separatedBy: .newlines) else { return }

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

                    } catch {
                        print(error)
                    }
                }
            } catch {
                print(error)
            }
            context.saveOrRollback()

            completion()
        }
    }
}
