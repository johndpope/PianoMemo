//
//  FolderMigrationTests.swift
//  Tests
//
//  Created by hoemoon on 15/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import XCTest
import CoreData
import Kuery
@testable import Piano

class FolderMigrationTests: XCTestCase {
    var testContext: NSManagedObjectContext!
    var sut: BulkUpdateOperation!
    let queue = OperationQueue()

    override func setUp() {
        testContext = TestHelper.testContext()
        UserDefaults.standard.set(false, forKey: BulkUpdateOperation.MigrationKey.didNotesContentMigration2.rawValue)
    }

    func testFolderMigaration() {
        let migration = expectation(description: "migration")
        var note1: Note!

        testContext.performAndWait {
            let folders = try? Query(Folder.self).execute()
            let notes = try? Query(Note.self).execute()
            assert(folders!.count == 0)
            assert(notes!.count == 0)

            note1 = Note.insert(into: testContext)
            note1.tags = "😃😍"
            let note2 = Note.insert(into: testContext)
            note2.tags = "🤩🥳"

            testContext.saveOrRollback()
            sut = BulkUpdateOperation(context: testContext) {
                let folders = try? Query(Folder.self).execute()
                XCTAssert(folders!.count != 0)
                XCTAssertNotNil(note1.folder)
                migration.fulfill()
            }
            queue.addOperation(sut)

        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
