//
//  MigrateLocallyOperation.swift
//  Piano
//
//  Created by hoemoon on 21/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData
import Kuery

protocol MigrationStateProvider {
    var didMigration: Bool { get }
}

class MigrateLocallyOperation: AsyncOperation, MigrationStateProvider {
    enum MigrationKey: String {
        case didNotesContentMigration1
        case didNotesContentMigration2
    }

    private let context: NSManagedObjectContext
    private var emojibasedFolders = Set<Folder>()

    private var didMigration1: Bool {
        return UserDefaults.standard.bool(
            forKey: MigrationKey.didNotesContentMigration1.rawValue)
    }
    private var didMigration2: Bool {
        return UserDefaults.standard.bool(
            forKey: MigrationKey.didNotesContentMigration2.rawValue)
    }

    var didMigration = false

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
                if notes.count == 0 {
                    self.state = .Finished
                    return
                }
                let folderCount = Folder.count(in: self.context)

                for note in notes {
                    if let existingNote = try self.context.existingObject(with: note.objectID) as? Note {
                        if !self.didMigration1 {
                            self.bulletUpdate(note: existingNote)
                        }
                        if !self.didMigration2, folderCount == 0 {
                            self.migrateToFolder(note: existingNote)
                        }
                    }
                }
                UserDefaults.doneContentMigration()
                UserDefaults.doneFolderMigration()
                self.didMigration = true
                self.state = .Finished
            } catch {
                print(error)
                self.state = .Finished
                NotificationCenter.default.post(name: .didFinishMigration, object: nil)
            }
        }
    }
}

extension MigrateLocallyOperation {
    private func migrateToFolder(note: Note) {
        if let tags = note.tags {
            if tags.emojis.contains("🔒") {
                note.isLocked = true
            } else if tags.emojis.count > 0 {
                let emoji = tags.emojis.first!
                if let folder = emojibasedFolders.filter({ $0.name == emoji }).first {
                    note.folder = folder
                } else {
                    let folder = Folder.insert(into: self.context)
                    folder.name = emoji
                    note.folder = folder
                    emojibasedFolders.insert(folder)
                }
            }
        }
    }

    private func bulletUpdate(note: Note) {
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
