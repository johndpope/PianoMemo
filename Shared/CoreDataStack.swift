//
//  CoreDataStack.swift
//  Piano
//
//  Created by hoemoon on 22/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

private let container: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Light")
    return container
}()

func createContainer(completion: @escaping (NSPersistentContainer) -> Void) {
    container.loadPersistentStores { _, error in
        if error == nil {
            DispatchQueue.main.async {
                completion(container)
            }
        }
    }
}
