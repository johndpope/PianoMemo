//
//  ImageUploaderTests.swift
//  Tests
//
//  Created by hoemoon on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import XCTest
import CoreData
@testable import Piano

class ImageUploaderTests: XCTestCase {
    var sut: ImageUploader!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        sut = ImageUploader()
        testContext = TestHlpers.testContext()
    }

    override func tearDown() {
    }

    func testUploadImage() {
        let image = ImageAttachment.insert(into: testContext)
        testContext.perform {
//            self.sut.processChangedLocalElements([image], in: testContext)

        }
    }
}
