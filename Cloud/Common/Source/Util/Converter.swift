//
//  Converter.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 19..
//  Copyright © 2018년 piano. All rights reserved.
//

import CoreData

internal class Converter {
    
    internal func cloud(conflict record: ConflictRecord, context: NSManagedObjectContext) {
        guard let server = record.server else {return}
        context.name = LOCAL_CONTEXT
        context.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: server.recordType)
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "\(KEY_RECORD_NAME) == %@", server.recordID.recordName)
            if let object = try? context.fetch(request).first as? NSManagedObject, let strongObject = object {
                strongObject.setValue(self.diff(with: record), forKey: KEY_RECORD_TEXT)
                print("strongObject :", strongObject)
            }
            if context.hasChanges {try? context.save()}
        }
    }
    
    private func diff(with record: ConflictRecord) -> String? {
        let a = record.ancestor?.value(forKey: KEY_RECORD_TEXT) as? String ?? ""
        let s = record.server?.value(forKey: KEY_RECORD_TEXT) as? String ?? ""
        let c = record.client?.value(forKey: KEY_RECORD_TEXT) as? String ?? ""
        
        let diff3Maker = Diff3Maker(ancestor: a, a: c, b: s)
        let diff3Chunks = diff3Maker.mergeInLineLevel().flatMap { chunk -> [Diff3Block] in
            if case let .change(oRange, aRange, bRange) = chunk {
                let oString = (a as NSString).substring(with: oRange)
                let aString = (c as NSString).substring(with: aRange)
                let bString = (s as NSString).substring(with: bRange)
                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: " ")
                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
            } else if case let .conflict(oRange, aRange, bRange) = chunk {
                let oString = (a as NSString).substring(with: oRange)
                let aString = (c as NSString).substring(with: aRange)
                let bString = (s as NSString).substring(with: bRange)
                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: " ")
                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
            } else {
                return [chunk]
            }
        }
        print(diff3Chunks)
        var result = c
        var offset = 0
        diff3Chunks.forEach {
            switch $0 {
            case .add(let index, let range):
                let replacement = (s as NSString).substring(with: range)
                print("add :", replacement)
                result.insert(contentsOf: replacement, at: c.index(c.startIndex, offsetBy: index+offset))
                offset += range.length
            case .delete(let range):
                let start = c.index(c.startIndex, offsetBy: range.location + offset)
                let end = c.index(c.startIndex, offsetBy: range.location + offset + range.length)
                result.removeSubrange(Range(uncheckedBounds: (lower: start, upper: end)))
                offset -= range.length
            case .change(_, let myRange, let serverRange):
                let replacement = (s as NSString).substring(with: serverRange)
                let start = c.index(c.startIndex, offsetBy: myRange.location + offset)
                let end = c.index(c.startIndex, offsetBy: myRange.location + offset + myRange.length)
                result.replaceSubrange(Range(uncheckedBounds: (lower: start, upper: end)), with: replacement)
                offset += serverRange.length - myRange.length
            default: break
            }
        }
        return result
    }
    
    internal func object(toRecord unit: ManagedUnit) -> ManagedUnit {
        guard let object = unit.object, let record = unit.record else {return unit}
        for key in object.entity.attributesByName.keys {
            let value = object.value(forKey: key)
            if key == "imageData" {
                record.setValue(createAsset(for: value), forKey: key)
            } else {
                guard key != KEY_RECORD_NAME, key != KEY_RECORD_DATA else {continue}
                record.setValue(value, forKey: key)
            }
        }
        for key in object.entity.relationshipsByName.keys {
            guard let isToMany = object.entity.relationshipsByName[key]?.isToMany else {continue}
            if !isToMany {
                record.setValue(reference(forRelationship: key, with: object), forKey: key)
            } else {
                record.setValue(reference(forRelationships: key, with: unit), forKey: key)
            }
        }
        return ManagedUnit(record: record, object: nil)
    }
    
    private func reference(forRelationship name: String, with object: NSManagedObject) -> CKReference? {
        guard let rObjectID = object.objectIDs(forRelationshipNamed: name).first else {return nil}
        guard let rObject = object.managedObjectContext?.object(with: rObjectID) else {return nil}
        guard let rRecordName = rObject.value(forKey: KEY_RECORD_NAME) as? String else {return nil}
        return CKReference(recordID: CKRecordID(recordName: rRecordName), action: .none)
    }
    
    private func reference(forRelationships name: String, with unit: ManagedUnit) -> Array<CKReference>? {
        guard let object = unit.object, let record = unit.record else {return nil}
        var referArray = (record.value(forKey: name) as? Array<CKReference>) ?? Array<CKReference>()
        for rObjectID in object.objectIDs(forRelationshipNamed: name) {
            guard let rObject = object.managedObjectContext?.object(with: rObjectID) else {return nil}
            guard let rRecordName = rObject.value(forKey: KEY_RECORD_NAME) as? String else {return nil}
            referArray.append(CKReference(recordID: CKRecordID(recordName: rRecordName), action: .none))
        }
        return referArray.isEmpty ? nil : referArray
    }
    
    private func createAsset(for any: Any?)-> CKAsset? {
        let fileName = UUID().uuidString.lowercased() + ".jpg"
        let fullURL = URL(fileURLWithPath: fileName, relativeTo: FileManager.default.temporaryDirectory)
        do {
            guard let data = any as? Data else {return nil}
            try data.write(to: fullURL)
            return CKAsset(fileURL: fullURL)
        } catch {
            return nil
        }
    }
    
    internal func record(toObject unit: ManagedUnit) {
        guard let record = unit.record, let object = unit.object else {return}
        for key in record.allKeys() where !systemField(key) {
            if key == "imageData" {
                guard let asset = record.value(forKey: key) as? CKAsset else {continue}
                object.setValue(try? Data(contentsOf: asset.fileURL), forKey: key)
            } else {
                if let ref = record.value(forKey: key) as? CKReference {
                    object.setValue(findObject(with: ref, key, object), forKey: key)
                } else if let refs = record.value(forKey: key) as? [CKReference] {
                    let isSet = (object.value(forKey: key) is NSSet)
                    let rObjects = isSet ? NSMutableSet() : NSMutableOrderedSet()
                    for ref in refs {
                        guard let rObject = findObject(with: ref, key, object) else {continue}
                        if isSet {
                            (rObjects as! NSMutableSet).add(rObject)
                        } else {
                            (rObjects as! NSMutableOrderedSet).add(rObject)
                        }
                    }
                    object.setValue(rObjects, forKey: key)
                } else {
                    object.setValue(record.value(forKey: key), forKey: key)
                }
            }
        }
    }
    
    private func systemField(_ key: String)-> Bool {
        return ["recordName", "createdBy", "createdAt",
                "modifiedBy", "modifiedAt", "changeTag"].contains(key)
    }
    
    private func findObject(with ref: CKReference, _ key: String, _ object: NSManagedObject) -> NSManagedObject? {
        guard let entityName = object.entity.relationshipsByName[key]?.destinationEntity?.name else {return nil}
        guard let context = object.managedObjectContext else {return nil}
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(KEY_RECORD_NAME) == %@", ref.recordID.recordName)
        request.includesPropertyValues = false
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first as? NSManagedObject
        } catch {
            return nil
        }
    }
    
}
