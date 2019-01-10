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

    // 실제 클라우드에 올리는 코드임.
    // 테스트 하려면 `_`을  제거해야 함
    // TODO: cloudKit에 대한 mock 만들기
    func _testExample() {
        let uploadExpectation = expectation(description: "upload success")
        var success: Bool?

        testContext.perform {
            let testImage = UIImage(named: "clipboard")!
            let image = ImageAttachment.insert(into: self.testContext)
            image.imageData = testImage.pngData() as NSData?

            self.cloudSetvice.upload([image], completion: { saved, _, _ in
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
