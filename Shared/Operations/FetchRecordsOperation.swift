//
//  FetchRecordsOperation.swift
//  Piano
//
//  Created by hoemoon on 24/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

class FetchRecordsOperation: AsyncOperation, ZoneChangeProvider {
    private let database: CKDatabase
    private let recordIDs: [CKRecord.ID]
    private var isMine: Bool {
        return database.databaseScope == .private
    }

    var newRecords = [RecordWrapper]()
    var removedReocrdIDs = [CKRecord.ID]()

    init(database: CKDatabase, recordIDs: [CKRecord.ID]) {
        self.database = database
        self.recordIDs = recordIDs
        super.init()
    }

    override func main() {
        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = {
            [weak self] recordsByRecordID, operationError in

            guard let self = self,
                let dict = recordsByRecordID else { return }

            dict.values.forEach {
                self.newRecords.append((self.isMine, $0))
            }
            self.state = .Finished
        }
        database.add(operation)
    }
}
