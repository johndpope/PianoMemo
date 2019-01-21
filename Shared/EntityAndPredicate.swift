//
//  EntityAndPredicate.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

final class EntityAndPredicate<A: NSManagedObject> {
    let entity: NSEntityDescription
    let predicate: NSPredicate

    init(entity: NSEntityDescription, predicate: NSPredicate) {
        self.entity = entity
        self.predicate = predicate
    }
}

extension EntityAndPredicate {
    var fetchRequest: NSFetchRequest<A> {
        let request = NSFetchRequest<A>()
        request.entity = entity
        request.predicate = predicate
        return request
    }
}

extension Sequence where Iterator.Element: NSManagedObject {
    func filter(_ entityAndPredicate: EntityAndPredicate<Iterator.Element>) -> [Iterator.Element] {
        let filtered = filter {
            guard $0.entity === entityAndPredicate.entity else { return false }
            return entityAndPredicate.predicate.evaluate(with: $0)
        }
        return Array(filtered)
    }
}
