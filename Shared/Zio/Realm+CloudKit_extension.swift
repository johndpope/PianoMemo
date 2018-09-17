//
//  Realm+CloudKit.swift
//  PianoNote
//
//  Created by 김범수 on 2018. 4. 2..
//  Copyright © 2018년 piano. All rights reserved.
//

/*
//import RealmSwift
import CloudKit

extension Note {

    func getRecordWithURL() -> NSDictionary {
        let scheme = Schema.Note.self

        self.ckMetaData
        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
        coder.finishDecoding()

        guard let asset = try? CKAsset(data: self.attributes) else { fatalError() }

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.content] = self.content as CKRecordValue
        record[scheme.attributes] = asset as CKRecordValue

        record[scheme.tags] = self.tags as CKRecordValue
        record[scheme.isPinned] = (self.isPinned ? 1 : 0) as CKRecordValue
        record[scheme.isLocked] = (self.isLocked ? 1 : 0) as CKRecordValue

        record[scheme.isInTrash] = (self.isInTrash ? 1 : 0) as CKRecordValue
        record[scheme.colorThemeCode] = self.colorThemeCode as CKRecordValue

        return NSDictionary(dictionary: [Schema.dicURLsKey: [asset.fileURL], Schema.dicRecordKey: record])
    }
}

extension RealmImageModel {
    
    func getRecordWithURL() -> NSDictionary {
        let scheme = Schema.Image.self
        
        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
        coder.finishDecoding()
        
        let noteRecordID = CKRecordID(recordName: noteRecordName, zoneID: record.recordID.zoneID)
        
        record[scheme.id] = self.id as CKRecordValue
        guard let asset = try? CKAsset(data: self.image) else { fatalError() }
        record[scheme.image] = asset
        
        record[scheme.noteRecordName] = CKReference(recordID: noteRecordID, action: .deleteSelf)
        record.setParent(noteRecordID)

        return NSDictionary(dictionary: [Schema.dicURLsKey: [asset.fileURL], Schema.dicRecordKey: record])
    }
}

extension RealmImageListModel {

    func getRecord() -> CKRecord {
        let scheme = Schema.ImageList.self

        let coder = NSKeyedUnarchiver(forReadingWith: self.ckMetaData)
        coder.requiresSecureCoding = true
        guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
        coder.finishDecoding()

        let noteRecordID = CKRecordID(recordName: noteRecordName, zoneID: record.recordID.zoneID)

        record[scheme.id] = self.id as CKRecordValue
        record[scheme.noteRecordName] = CKReference(recordID: noteRecordID, action: .deleteSelf)
        record[scheme.imageList] = self.imageIDs as CKRecordValue
        record.setParent(noteRecordID)

        return record
    }
}

extension CKRecord {

    func getMetaData() -> Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()

        return Data(referencing: data)
    }

    func parseRecord(isShared: Bool) -> Object? {
        switch self.recordType {
            case RealmTagsModel.recordTypeString: return parseTagsRecord()
            case RealmNoteModel.recordTypeString: return parseNoteRecord(isShared: isShared)
            case RealmImageModel.recordTypeString: return parseImageRecord(isShared: isShared)
            case RealmCKShare.recordTypeString: return parseShare(isShared: isShared)
            case RealmRecordTypeString.latestEvent.rawValue:
                //special case!
                if let date = self[Schema.LatestEvent.date] as? Date {
                    UserDefaults.standard.set(date, forKey: Schema.LatestEvent.key)
                    UserDefaults.standard.synchronize()
                }
                fallthrough
            default: return nil
        }
    }
    
    private func parseTagsRecord() -> RealmTagsModel? {
        let newTagsModel = RealmTagsModel()
        let schema = Schema.Tags.self
        
        guard let tags = self[schema.tags] as? String,
            let id = self[schema.id] as? String else {return nil}
        
        newTagsModel.tags = tags
        newTagsModel.id = id
        newTagsModel.ckMetaData = self.getMetaData()
        
        return newTagsModel
    }
    
    private func parseNoteRecord(isShared: Bool) -> RealmNoteModel? {
        let newNoteModel = RealmNoteModel()
        let schema = Schema.Note.self
        
        guard let id = self[schema.id] as? String,
                let content = self[schema.content] as? String,
                let attributesAsset = self[schema.attributes] as? CKAsset,
                let attributes = try? Data(contentsOf: attributesAsset.fileURL),
                let tags = self[schema.tags] as? String,
                let isPinned = self[schema.isPinned] as? Int,
                let isInTrash = self[schema.isInTrash] as? Int,
                let colorThemeCode = self[schema.colorThemeCode] as? String else {return nil}

        newNoteModel.id = id
        newNoteModel.content = content
        newNoteModel.attributes = attributes
        newNoteModel.recordName = self.recordID.recordName
        newNoteModel.ckMetaData = self.getMetaData()
        newNoteModel.isModified = self.modificationDate ?? Date()
        newNoteModel.tags = tags
        
        defer {
            try? FileManager.default.removeItem(at: attributesAsset.fileURL)
        }
        
        if isShared {
            if let realm = try? Realm(),
                let currentModel = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: id) {
                newNoteModel.isPinned = currentModel.isPinned
                newNoteModel.isLocked = currentModel.isLocked
            }
        } else {
            newNoteModel.isPinned = isPinned == 1
            newNoteModel.isInTrash = isInTrash == 1
        }
        
        newNoteModel.colorThemeCode = colorThemeCode

        newNoteModel.isInSharedDB = isShared
        
        newNoteModel.shareRecordName = share?.recordID.recordName
        
        return newNoteModel
    }
    
    private func parseImageRecord(isShared: Bool) -> RealmImageModel? {
        let newImageModel = RealmImageModel()
        let schema = Schema.Image.self
        
        guard let id = self[schema.id] as? String,
            let imageAsset = self[schema.image] as? CKAsset,
            let image = try? Data(contentsOf: imageAsset.fileURL),
            let noteReference = self[schema.noteRecordName] as? CKReference
            else {return nil}

        newImageModel.id = id
        newImageModel.image = image
        newImageModel.noteRecordName = noteReference.recordID.recordName
        newImageModel.recordName = self.recordID.recordName
        newImageModel.ckMetaData = self.getMetaData()
        newImageModel.isInSharedDB = isShared

        defer {
            try? FileManager.default.removeItem(at: imageAsset.fileURL)
        }
        
        return newImageModel
    }

    private func parseImageListRecord(isShared: Bool) -> RealmImageListModel? {
        let newImageListModel = RealmImageListModel()
        let scheme = Schema.ImageList.self

        guard let id = self[scheme.id] as? String,
                let noteReference = self[scheme.noteRecordName] as? CKReference,
                let imageList = self[scheme.imageList] as? String else { return nil}

        newImageListModel.id = id
        newImageListModel.noteRecordName = noteReference.recordID.recordName
        newImageListModel.imageIDs = imageList

        return newImageListModel
    }
    
    private func parseShare(isShared: Bool) -> RealmCKShare? {
        let newShareModel = RealmCKShare()
        
        guard let share = self as? CKShare else {return nil}
        newShareModel.recordName = share.recordID.recordName
        newShareModel.shareData = self.archieve()
        
        return newShareModel
    }
}

*/
