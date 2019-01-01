//
//  StorageServiceFunctionalTests.swift
//  Tests
//
//  Created by hoemoon on 24/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import XCTest
import Foundation
@testable import Piano

class StorageServiceFunctionalTests: XCTestCase {
    var storageService: StorageService!

    override func setUp() {
        storageService = StorageService()
        storageService.setup()
    }

    override func tearDown() {

    }

    func testCreateNote() {
        storageService.local
            .create(
            attributedString: NSAttributedString(string: "aaa"),
            tags: "bbb") {}

        expectation(
            forNotification: .NSManagedObjectContextDidSave,
            object: storageService.local.mainContext) { _ -> Bool in
                return true
        }

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error, "Save did not occur")
        }
    }
}
