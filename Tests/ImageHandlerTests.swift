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
    lazy var mockPersistantContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "Light")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // Make it simpler in test env

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (description, error) in
            // Check if the data store is in memory
            precondition( description.type == NSInMemoryStoreType )

            // Check if creating container wrong
            if let error = error {
                fatalError("Create an in-mem coordinator failed \(error)")
            }
        }
        return container
    }()

    var imageHandler: ImageHandlable!

    override func setUp() {
        imageHandler = ImageHandler(context: mockPersistantContainer.viewContext)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSaveImage() {
        let image = UIImage(named: "clipboard")
        XCTAssert(image != nil)
        let idExpectation = expectation(description: "image id")
        var imageID: String?
        imageHandler.saveImage(image: image) {
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
        imageHandler.saveImage(image: image) {
            guard let id = $0 else { fatalError() }
            self.imageHandler.requestImage(id: id, completion: {
                resultImage = $0
                imageExpectation.fulfill()
            })
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(resultImage != nil)
    }

}
