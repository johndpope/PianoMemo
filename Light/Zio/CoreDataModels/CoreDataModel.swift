//
//  CoreDataModel.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreGraphics
import CoreData
import UIKit

/*
 코어데이터는 xcdatamoldeld에서 입력하면 자동으로 생성되므로 여기서는 익스텐션만 추가한다
 */

@objc protocol Recordable {
    var recordName: String? { get set }
    var isInSharedDB: Bool { get set }
    var ckMetaData: Data? { get set }
    @objc optional func getRecord() -> CKRecord
    @objc optional func getRecordWithURL() -> NSDictionary
}

/*
 Adding new field
 
 1 CoreDataModel
 2. Sync scheme
 3. Realm+Cloudkit -> getRecord() & parse__Record()
 4. Appdelegate -> increment MigrationNumber
 
 */
extension Note: Recordable {
    
    static let recordTypeString = "Note"
    
    //여기는 클라우드 데이터베이스가 추가되는 부분이어서 PianoNote 프로젝트를 가져와 주석으로 해놨어요!
    static func getNewNodel(context: NSManagedObjectContext) -> Note {
        //        let zone = CKRecordZone(zoneName: RxCloudDatabase.privateRecordZoneName)
        //        let id = Util.share.getUniqueID()
        //        let record = CKRecord(recordType: Note.recordTypeString, zoneID: zone.zoneID)
        
        let newModel = Note(context: context)
        //코어데이터에서는 id값을 사용하지 않고 predicate으로 바로 fetch하는 구조라 id를 note의 필드에 추가해놓지는 않았어요.
        //        note.id = id
        
        //        newModel.recordName = record.recordID.recordName
        //        newModel.ckMetaData = record.getMetaData()
        
        
        return newModel
        
    }
    
    static func fetch(predicate: NSPredicate, on context: NSManagedObjectContext) -> [Note] {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        
        do {
            request.predicate = predicate
            let results = try context.fetch(request)
            return results
        } catch {
            // TODO: 에러처리 하기
            fatalError()
        }
    }
    
}

extension NSManagedObjectContext {
    
    internal func saveIfNeeded() {
        guard hasChanges else { return }
        
        do {
            try save()
        } catch {
            print("컨텍스트 저장하다 에러: \(error)")
        }
    }
    
}
