//
//  ConflictResolver.swift
//  PianoNote
//
//  Created by 김범수 on 2018. 4. 3..
//  Copyright © 2018년 piano. All rights reserved.
//
/*
import CloudKit

extension RxCloudDatabase {
    func merge(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, completion: @escaping (Bool)->()) {
        let myModified = myRecord.modificationDate ?? Date()
        let serverModified = serverRecord.modificationDate ?? Date()
        
        switch ancestor.recordType {
        case RealmNoteModel.recordTypeString:
            mergeNote(ancestor: ancestor, myRecord: myRecord, serverRecord: serverRecord, myModified: myModified, serverModified: serverModified, completion: completion)
            
        case RealmTagsModel.recordTypeString:
            
            if myModified.compare(serverModified) == .orderedDescending {
                serverRecord[Schema.Tags.tags] = myRecord[Schema.Tags.tags]
                completion(true)
            } else {
                completion(false)
            }
        default: break
        }
        
        
    }
    
    private func mergeNote(ancestor: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, myModified: Date, serverModified: Date, completion: @escaping (Bool) -> ()) {
        
        if let synchronizer = synchronizers[myRecord.recordID.recordName] {
            //DO diff3 here with ancestor: myrecord, a: textView.text b: b
            synchronizer.resolveConflict(ancestorRecord: ancestor, myRecord: myRecord, serverRecord: serverRecord, completion: completion)
            return
        }
        
        
        if myModified.compare(serverModified) == .orderedDescending {
            
            if let serverCategory = serverRecord[Schema.Note.tags] as? String,
                let myCategory = myRecord[Schema.Note.tags] as? String,
                serverCategory != myCategory {
                
                serverRecord[Schema.Note.tags] = myRecord[Schema.Note.tags]
                completion(true)
                return
            }
            
        }
        
        completion(false)
    }
    
}
 
 */
