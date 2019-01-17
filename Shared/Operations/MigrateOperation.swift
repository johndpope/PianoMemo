//
//  MigrateOperation.swift
//  Piano
//
//  Created by hoemoon on 21/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData
import Kuery

class MigrateOperation: AsyncOperation {
    enum MigrationKey: String {
        case didNotesContentMigration1
        case didNotesContentMigration2
    }

    private let context: NSManagedObjectContext
    private var lockFolder: Folder?
    private var trashFolder: Folder?
    private var emojibasedFolders = Set<Folder>()

    private var didMigration1: Bool {
        return UserDefaults.standard.bool(
            forKey: MigrationKey.didNotesContentMigration1.rawValue)
    }
    private var didMigration2: Bool {
        return UserDefaults.standard.bool(
            forKey: MigrationKey.didNotesContentMigration2.rawValue)
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }

    override func main() {
        if didMigration1 && didMigration2 {
            self.state = .Finished
            return
        }
        context.perform { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(name: .didStartMigration, object: nil)
            do {
                let notes = try Query(Note.self).execute()
                if !self.didMigration1 {
                    for note in notes {
                        if let existingNote = try self.context.existingObject(with: note.objectID) as? Note {
                            self.bulletUpdate(note: existingNote)
                        }
                    }
                    UserDefaults.doneContentMigration()
                }

                if !self.didMigration2 {
                    let folder = Folder.insert(into: self.context, type: .all)
                    folder.name = "All note folder name"

                    for note in notes {
                        if let existingNote = try self.context.existingObject(with: note.objectID) as? Note {
                            self.migrateToFolder(note: existingNote)
                        }
                    }
                    UserDefaults.doneFolderMigration()
                }
                self.context.saveOrRollback()
                self.state = .Finished
                NotificationCenter.default.post(name: .didFinishMigration, object: nil)
            } catch {
                print(error)
                self.state = .Finished
                NotificationCenter.default.post(name: .didFinishMigration, object: nil)
            }
        }
    }
}

extension MigrateOperation {
    private func migrateToFolder(note: Note) {
        if let tags = note.tags {
            if tags.emojis.contains("🔒") {
                if let lockFolder = lockFolder {
                    note.folder = lockFolder
                } else {
                    lockFolder = Folder.insert(into: self.context, type: .locked)
                    lockFolder?.name = "🔒"
                    note.folder = lockFolder
                }
            } else if note.isRemoved {
                if let trashFolder = trashFolder {
                    note.folder = trashFolder
                } else {
                    trashFolder = Folder.insert(into: self.context, type: .removed)
                    trashFolder?.name = "trash folder name"
                    note.folder = trashFolder
                }
            } else if tags.emojis.count > 0 {
                let emoji = tags.emojis.first!
                if let folder = emojibasedFolders.filter({ $0.name == emoji }).first {
                    note.folder = folder
                } else {
                    let folder = Folder.insert(into: self.context, type: .custom)
                    folder.name = emoji
                    note.folder = folder
                    emojibasedFolders.insert(folder)
                }
            }
        }
        note.markUploadReserved()
    }

    private func bulletUpdate(note: Note) {
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
    }
}
