//
//  RecordHandlable.swift
//  Piano
//
//  Created by hoemoon on 31/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData
import Kuery

protocol RecordHandlable: class {
    var backgroundContext: NSManagedObjectContext! { get }
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: @escaping () -> Void)
    func remove(recordID: CKRecord.ID, completion: @escaping () -> Void)
}

extension RecordHandlable {
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        if record.recordType.description == Record.note {
            backgroundContext.performAndWait {
                let note = Note.fetch(in: self.backgroundContext) { request in
                    request.predicate = Note.predicateForRecordID(record.recordID)
                    request.returnsObjectsAsFaults = false
                    }.first
                switch note {
                case .some(let note):
                    if let local = note.modifiedAt,
                        let remote = record[NoteField.modifiedAtLocally] as? NSDate,
                        (local as Date) < (remote as Date) {

                        self.updateNote(origin: note, record: record, isMine: isMine, completion: completion)
                    }
                    completion()
                case .none:
                    self.createNote(record: record, isMine: isMine, completion: completion)
                }
            }
        } else if record.recordType.description == Record.image {
            backgroundContext.performAndWait {
                let image = ImageAttachment.fetch(in: self.backgroundContext) { request in
                    request.predicate = ImageAttachment.predicateForRecordID(record.recordID)
                    request.returnsObjectsAsFaults = false
                    }.first

                switch image {
                case .some(let image):
                    if let local = image.modifiedAt,
                        let remote = record[ImageField.modifiedAtLocally] as? NSDate,
                        (local as Date) < (remote as Date) {

                        self.updateImage(origin: image, record: record, isMine: isMine, completion: completion)
                    }
                    completion()
                case .none:
                    self.createImage(record: record, isMine: isMine, completion: completion)
                }
            }
        }
    }

    func remove(recordID: CKRecord.ID, completion: @escaping () -> Void) {
        backgroundContext.performAndWait {
            let note = Note.fetch(in: self.backgroundContext) { request in
                request.predicate = Note.predicateForRecordID(recordID)
                }.first
            note?.markForLocalDeletion()
            let image = ImageAttachment.fetch(in: self.backgroundContext) { request in
                request.predicate = ImageAttachment.predicateForRecordID(recordID)
                }.first
            image?.markForLocalDeletion()
            self.backgroundContext.saveOrRollback()
            completion()
        }
    }
}

extension RecordHandlable {
    private func createNote(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        let new = Note.insert(into: self.backgroundContext, needUpload: false)
        performUpdate(origin: new, with: record, isMine: isMine)
        backgroundContext.saveOrRollback()
        completion()
    }

    private func updateNote(origin: Note, record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        performUpdate(origin: origin, with: record, isMine: isMine)
        backgroundContext.saveOrRollback()
        completion()
    }

    private func folderize(origin: Note, with record: CKRecord) {
        guard let folderName = record[NoteField.folder] as? String else { return }
        do {
            let result = try Query(Folder.self)
                .filter(\Folder.name == folderName)
                .execute()
                .first
            switch result {
            case .some(let folder):
                origin.folder = folder
            case .none:
                let newFolder = Folder.insert(into: backgroundContext, type: .custom)
                newFolder.name = folderName
                origin.folder = newFolder
            }
        } catch {
            print(error)
        }
    }

    private func createImage(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        let new = ImageAttachment.insert(into: self.backgroundContext)
        performUpdate(origin: new, with: record, isMine: isMine)
        backgroundContext.saveOrRollback()
        completion()
    }

    private func updateImage(origin: ImageAttachment, record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        performUpdate(origin: origin, with: record, isMine: isMine)
        backgroundContext.saveOrRollback()
        completion()
    }

    private func performUpdate(origin: NSManagedObject, with record: CKRecord, isMine: Bool) {
        let attributes = origin.entity.attributesByName
        var transformableAttributeKeys = Set<String>()
        for (key, attributeDescription) in attributes where attributeDescription.attributeType == NSAttributeType.transformableAttributeType {
            transformableAttributeKeys.insert(key)
        }
        origin.setValue(isMine, forKey: "isMine")
        origin.setValue(record.archived, forKey: "recordArchive")
        if var dict = record.allAttributeValuesAsManagedObjectAttributeValues(usingContext: backgroundContext) {
            dict = replaceAssets(in: dict)
            dict = transformAttributes(in: dict, keys: transformableAttributeKeys)
            dict = replaceDateKeys(in: dict)
            origin.setValuesForKeys(dict)
        }
        if let note = origin as? Note {
            folderize(origin: note, with: record)
        }
    }

    private func transformAttributes(in dictionary: [String: AnyObject], keys: Set<String>) -> [String: AnyObject] {
        var returnDict = [String: AnyObject]()
        for (key, value) in dictionary {
            if keys.contains(key) {
                if let data = dictionary[key] as? Data {
                    let unarchived = NSKeyedUnarchiver.unarchiveObject(with: data) as AnyObject
                    returnDict[key] = unarchived
                }
            } else {
                returnDict[key] = value
            }
        }
        return returnDict
    }

    private func replaceAssets(in dictionary: [String: AnyObject]) -> [String: AnyObject] {
        var returnDict = [String: AnyObject]()
        for (key, value) in dictionary {
            if let val = value as? CKAsset {
                if let assetData = NSData(contentsOfFile: val.fileURL.path) {
                    returnDict[key] = assetData
                }
            } else {
                returnDict[key] = value
            }
        }
        return returnDict
    }

    private func replaceDateKeys(in dictionary: [String: AnyObject]) -> [String: AnyObject] {
        var returnDict = [String: AnyObject]()
        for (key, value) in dictionary {
            if key == "createdAtLocally" {
                returnDict["createdAt"] = value
            } else if key == "modifiedAtLocally" {
                returnDict["modifiedAt"] = value
            } else {
                returnDict[key] = value
            }
        }
        return returnDict
    }
}

extension CloudService: RecordHandlable {}

extension CKRecord {
    func allAttributeKeys(usingAttributesByNameFromEntity attributesByName: [String: NSAttributeDescription]) -> [String] {
        var filtered = allKeys().filter { attributesByName[$0] != nil }
        filtered.append(contentsOf: ["createdAtLocally", "modifiedAtLocally"])
        if let index = filtered.firstIndex(of: "createdAt") {
            filtered.remove(at: index)
        }
        if let index = filtered.firstIndex(of: "modifiedAt") {
            filtered.remove(at: index)
        }
        return filtered
    }

    fileprivate func allAttributeValuesAsManagedObjectAttributeValues(usingContext context: NSManagedObjectContext) -> [String: AnyObject]? {
        if let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[self.recordType] {
            return self.dictionaryWithValues(forKeys: self.allAttributeKeys(usingAttributesByNameFromEntity: entity.attributesByName)) as [String: AnyObject]?
        } else {
            return nil
        }
    }
}
