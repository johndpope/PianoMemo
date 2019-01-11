//
//  ImageCloudServiceTests.swift
//  Tests
//
//  Created by hoemoon on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import XCTest
import CoreData
import CloudKit
@testable import Piano

class MockCloudService: RemoteProvider {
    var doneUpload: Bool = false

    func setup(context: NSManagedObjectContext) {
    }

    func fetchChanges(in scope: CKDatabase.Scope, needByPass: Bool, needRefreshToken: Bool, completion: @escaping (Bool) -> Void) {
    }

    func upload(
        _ notes: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {
        doneUpload = true
        completion?(nil, nil, nil)
    }

    func remove(
        _ notes: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {
    }

    func fetchUserID(completion: @escaping () -> Void) {
    }

    func createZone(completion: @escaping (Bool) -> Void) {
    }
}

class ImageCloudServiceTests: XCTestCase {
    var testContext: NSManagedObjectContext!
    var cloudSetvice: MockCloudService!

    override func setUp() {
        testContext = TestHelper.testContext()
        cloudSetvice = MockCloudService()
        cloudSetvice.setup(context: testContext)
    }

    override func tearDown() {
    }

    // 실제 클라우드에 올리는 코드임.
    // 테스트 하려면 `_`을  제거해야 함
    // TODO: cloudKit에 대한 mock 만들기
    func _uploadImageTest() {
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

    func testMockImageUpload() {
        let uploadExpectation = expectation(description: "upload success")
        testContext.perform {
            let testImage = UIImage(named: "clipboard")!
            let image = ImageAttachment.insert(into: self.testContext)
            image.imageData = testImage.pngData() as NSData?

            self.cloudSetvice.upload([image], completion: { _, _, _ in
                uploadExpectation.fulfill()
            })
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(cloudSetvice.doneUpload == true)
    }
}
