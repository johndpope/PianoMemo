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
        sut = FolderHandler(context: testContext)
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

    func testUpdateRemoveFolder() {
        let removeFolder = expectation(description: "remove Folder")
        noteHandler.create(content: "nnnnnn", tags: "") { note in
            XCTAssertNotNil(note)
            self.sut.create(name: "Hello Folder") { folder in
                XCTAssert(folder != nil)
                folder!.notes.insert(note!)

                self.sut.remove(folders: [folder!], completion: { (success) in
                    XCTAssertTrue(success)

                    XCTAssert(note!.isRemoved == true)
                    XCTAssert(note!.markedForUploadReserved == true)
                    removeFolder.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testAddNoteToFolder() {
        let addNoteToFolder = expectation(description: "add notes to folder")
        noteHandler.create(content: "nnnnnn", tags: "") { note in
            XCTAssertNotNil(note)
            self.sut.create(name: "hello") { folder in
                self.sut.add(notes: [note!], to: folder!, completion: { success in
                    XCTAssertTrue(success)
                    XCTAssertTrue(folder!.notes.count != 0)
                    XCTAssertTrue(folder?.notes.first?.folder?.name! == "hello")
                    addNoteToFolder.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRemoveNotesFromFolder() {
        let removeNotesFromFolder = expectation(description: "remove Notes FromFolder")
        noteHandler.create(content: "nnnnnn", tags: "") { note in
            XCTAssertNotNil(note)
            self.sut.create(name: "hello") { folder in
                self.sut.remove(notes: [note!], from: folder!, completion: { _ in
                    XCTAssert(folder!.notes.count == 0)
                    XCTAssert(note!.isRemoved == true)
                    removeNotesFromFolder.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testMoveNoteToAnotherFolderTest() {
        let moveNote = expectation(description: "move note to another folder")
        noteHandler.create(content: "nnnnnn", tags: "") { note in
            XCTAssertNotNil(note)
            self.sut.create(name: "hello") { helloFolder in
                self.sut.add(notes: [note!], to: helloFolder!, completion: { success in
                    XCTAssertTrue(success)
                    self.sut.create(name: "world", completion: { worldFolder in
                        self.sut.move(notes: [note!], from: helloFolder!, to: worldFolder!, completion: { success in
                            XCTAssertTrue(success)
                            XCTAssert(worldFolder!.notes.count > 0)
                            XCTAssert(worldFolder!.notes.contains(note!) == true)
                            moveNote.fulfill()
                        })
                    })
                })
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
