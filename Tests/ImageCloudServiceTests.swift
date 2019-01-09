//
//  ImageCloudServiceTests.swift
//  Tests
//
//  Created by hoemoon on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import XCTest
import CoreData
@testable import Piano

class ImageCloudServiceTests: XCTestCase {
    var testContext: NSManagedObjectContext!
    var cloudSetvice: CloudService!

    override func setUp() {
        testContext = TestHlpers.testContext()
        cloudSetvice = CloudService(context: testContext)
    }

    override func tearDown() {
    }

    func testExample() {
        let uploadExpectation = expectation(description: "upload success")
        var success: Bool?

        testContext.perform {
            let testImage = UIImage(named: "clipboard")!
            let image = ImageAttachment.insert(into: self.testContext)
            image.imageData = testImage.pngData() as NSData?

            self.cloudSetvice.upload([image], completion: { saved, ids, error in
                print(saved)
                if let saved = saved, saved.count > 0 {
                    success = true
                    uploadExpectation.fulfill()
                }
            })
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotNil(success)
    }
}
