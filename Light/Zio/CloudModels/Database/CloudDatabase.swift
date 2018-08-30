//
//  CloudDatabase.swift
//  PianoNote
//
//  Created by 김범수 on 2018. 4. 2..
//  Copyright © 2018년 piano. All rights reserved.
//
/*
import CloudKit
import UIKit

class CloudPublicDatabase: RxCloudDatabase {

    public override init(database: CKDatabase) {
        super.init(database: database)

        saveQuerySubscription(for: RealmRecordTypeString.latestEvent.rawValue)
    }

    public func handleNotification() {
        query(for: RealmRecordTypeString.latestEvent.rawValue)
    }
}

class CloudPrivateDatabase: RxCloudDatabase {

    public override init(database: CKDatabase) {
        super.init(database: database)

        saveQuerySubscription(for: RealmTagsModel.recordTypeString)
        saveQuerySubscription(for: RealmNoteModel.recordTypeString)
        saveQuerySubscription(for: RealmImageModel.recordTypeString)
    }

    public func handleNotification() {
        let customZone = CKRecordZone(zoneName: RxCloudDatabase.privateRecordZoneName)
        fetchZoneChanges(in: [customZone.zoneID])
    }
    
}

class CloudSharedDatabase: RxCloudDatabase {
    public override init(database: CKDatabase) {
        super.init(database: database)

        saveDatabaseSubscription()
    }

    public func handleNotification() {
        fetchDatabaseChanges()
    }
}

*/
