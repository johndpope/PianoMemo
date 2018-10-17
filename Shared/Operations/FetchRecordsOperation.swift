//
//  FetchRecordsOperation.swift
//  Piano
//
//  Created by hoemoon on 17/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class AddFetcedRecordsOperation: Operation {
    var isMine: Bool?
    var recordIDs: [CKRecord.ID]?
    var recordsByRecordID: [CKRecord.ID : CKRecord]?
    var completion: (() -> Void)?

    private let context: NSManagedObjectContext
    private let queue: OperationQueue
    init(context: NSManagedObjectContext, queue: OperationQueue) {
        self.context = context
        self.queue = queue
        super.init()
    }

    override func main() {
        guard let isMine = isMine,
            let recordIDs = recordIDs,
            let recordsByRecordID = recordsByRecordID,
            let completion = completion else { return }

        recordIDs.forEach {
            if let record = recordsByRecordID[$0] {
                let operation = AddOperation(record, context: context, isMine: isMine)
                queue.addOperation(operation)
            }
        }
        queue.addOperation(BlockOperation(block: completion))
    }
}

