//
//  ImageHandlerTests.swift
//  Tests
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import XCTest
import CoreData
@testable import Piano

class ImageHandlerTests: XCTestCase {
    var sut: ImageHandlable!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        testContext = TestHelper.testContext()
        sut = ImageHandler(context: testContext)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSaveImage() {
        let image = UIImage(named: "clipboard")
        XCTAssert(image != nil)
        let idExpectation = expectation(description: "image id")
        var imageID: String?
        sut.saveImage(image!) {
            imageID = $0
            idExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(imageID != nil)
    }

    func testRequestImage() {
        let imageExpectation = expectation(description: "image")
        var resultImage: UIImage?
        let image = UIImage(named: "clipboard")
        sut.saveImage(image!) {
            guard let id = $0 else { fatalError() }
            self.sut.requestImage(id: id, completion: {
                resultImage = $0
                imageExpectation.fulfill()
            })
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(resultImage != nil)
    }

    func testSaveImages() {
        let saveImages = expectation(description: "saveImages")
        let image1 = UIImage(named: "clipboard")!
        let image2 = UIImage(named: "clipboard")!

        sut.saveImages([image1, image2]) { ids in
            XCTAssertNotNil(ids)
            saveImages.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testAllImages() {
        let allimages = expectation(description: "all images")
        let image1 = UIImage(named: "clipboard")!
        let image2 = UIImage(named: "clipboard")!

        sut.saveImages([image1, image2]) { ids in
            self.sut.requetAllImages(completion: { results in
                switch results {
                case .success(let ids):
                    XCTAssert(ids.count == 2)
                case .failure:
                    XCTFail("all image failed")
                }
                allimages.fulfill()
            })
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
