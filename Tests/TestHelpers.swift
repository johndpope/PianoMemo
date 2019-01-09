//
//  TestHelpers.swift
//  Tests
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

class TestHlpers {
    static var mockPersistantContainer: NSPersistentContainer = {
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

    static func testContext() -> NSManagedObjectContext {
        return mockPersistantContainer.viewContext
    }
}
