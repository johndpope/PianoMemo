//
//  FolderHandlerTests.swift
//  Tests
//
//  Created by hoemoon on 11/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import XCTest
import CoreData
@testable import Piano

class FolderHandlerTests: XCTestCase {
    var sut: FolderHandlable!
    var noteHandler: NoteHandlable!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        testContext = TestHelper.testContext()
        noteHandler = NoteHandler(context: testContext)
        sut = FolderHandler()
        sut.setup(context: testContext)
    }

    override func tearDown() {
        sut = nil
        testContext = nil
    }

    func testCreateFolder() {
        let create = expectation(description: "create")
        sut.create(name: "Hello Folder") { folder in
            create.fulfill()
            XCTAssert(folder != nil)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testUpdateFolderName() {
        let updateName = expectation(description: "update name")
        noteHandler.create(content: "nnnnnn", tags: "") { note in
            XCTAssertNotNil(note)
            self.sut.create(name: "Hello Folder") { folder in
                XCTAssert(folder != nil)
                folder!.notes.insert(note!)

                self.sut.update(folder: folder!, newName: "new", completion: { success in
                    XCTAssertTrue(success)

                    XCTAssertTrue(note!.folder!.name == "new")
                    updateName.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
