//
//  BasicCoreDataTests.swift
//  Tests
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import XCTest
import Piano

class BasicCoreDataTests: XCTestCase {
    var localStorageService: LocalStorageService!

    override func setUp() {
        localStorageService = MockLocalStorageService()
    }

    override func tearDown() {
        localStorageService = nil
    }

    func testCreate() {
        localStorageService.create(attributedString: NSAttributedString(), tags: String()) {

        }

        expectation(
            forNotification: .NSManagedObjectContextDidSave,
            object: localStorageService.viewContext) {
                _ in
                return true
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error, "Save did not occur")
        }
    }
}
