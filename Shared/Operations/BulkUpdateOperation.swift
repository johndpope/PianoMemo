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
import Kuery

class BulkUpdateOperation: AsyncOperation {
    enum MigrationKey: String {
        case didNotesContentMigration1
        case didNotesContentMigration2
    }

    private let context: NSManagedObjectContext
    private let completion: () -> Void
    private let request: NSFetchRequest<Note>
    private var lockFolder: Folder?
    private var trashFolder: Folder?
    private var emojibasedFolders = Set<Folder>()

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
                let folders = try Query(Folder.self).execute()
                guard folders.count == 0 else {
                    self.state = .Finished
                    self.completion()
                    return
                }
                let notes = try Query(Note.self).execute()

                let folder = Folder.insert(into: self.context, type: .allNote)
                folder.name = "All note folder name"

//                for note in notes {
//                    if let existingNote = try self.context.existingObject(with: note.objectID) as? Note {
//                        if !UserDefaults.standard.bool(
//                            forKey: MigrationKey.didNotesContentMigration1.rawValue) {
//                            self.bulletUpdate(note: existingNote)
//                            UserDefaults.doneContentMigration()
//                        }
//                        self.migrateToFolder(note: existingNote)
//                        print("existingNote")
//
//                        if !UserDefaults.standard.bool(
//                            forKey: MigrationKey.didNotesContentMigration2.rawValue) {
//                            self.migrateToFolder(note: existingNote)
//                            print("existingNote")
//                            UserDefaults.doneFolderMigration()
//                        }
//                    }
//                }

                if !UserDefaults.standard.bool(
                    forKey: MigrationKey.didNotesContentMigration2.rawValue) {
                    for note in notes {
                        if let existingNote = try self.context.existingObject(with: note.objectID) as? Note {
                            self.migrateToFolder(note: existingNote)
                        }
                    }
                    UserDefaults.doneFolderMigration()
                }

                self.context.saveOrRollback()
                self.state = .Finished
                self.completion()
            } catch {
                print(error)
                self.state = .Finished
                self.completion()
            }
        }
    }
}

extension BulkUpdateOperation {
    private func migrateToFolder(note: Note) {
        if let tags = note.tags {
            if tags.emojis.contains("🔒") {
                if let lockFolder = lockFolder {
                    lockFolder.notes.insert(note)
                } else {
                    lockFolder = Folder.insert(into: self.context, type: .prepared)
                    lockFolder?.name = "🔒"
                    lockFolder?.notes.insert(note)
                }
            } else if note.isRemoved {
                if let trashFolder = trashFolder {
                    trashFolder.notes.insert(note)
                } else {
                    trashFolder = Folder.insert(into: self.context, type: .prepared)
                    trashFolder?.name = "trash folder name"
                    trashFolder?.notes.insert(note)
                }
            } else if tags.emojis.count > 0 {
                let emoji = tags.emojis.first!
                if let folder = emojibasedFolders.filter({ $0.name == emoji }).first {
                    folder.notes.insert(note)
                } else {
                    let folder = Folder.insert(into: self.context, type: .userCreated)
                    folder.name = emoji
                    folder.notes.insert(note)
                    emojibasedFolders.insert(folder)
                }
            }
        }
        note.markUploadReserved()
    }

    private func bulletUpdate(note: Note?) {
        switch note {
        case .some(let note):
            note.markUploadReserved()
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
}
