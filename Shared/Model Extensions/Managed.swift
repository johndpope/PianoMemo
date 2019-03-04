//
//  Managed.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol Managed: class, NSFetchRequestResult {
    static var entity: NSEntityDescription { get }
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    static var defaultPredicate: NSPredicate { get }
    var managedObjectContext: NSManagedObjectContext? { get }
}

protocol DefaultManaged: Managed {}

extension DefaultManaged {
    static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }
}

extension Managed {
    static var defaultSortDescriptors: [NSSortDescriptor] { return [] }
    static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }
    static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.predicate = defaultPredicate
        return request
    }
    static func predicate(format: String, _ args: CVarArg...) -> NSPredicate {
        let p = withVaList(args) { NSPredicate(format: format, arguments: $0) }
        return predicate(p)
    }

    static func predicate(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [defaultPredicate, predicate])
    }
}

extension Managed where Self: NSManagedObject {
    static var entity: NSEntityDescription { return entity() }
    static var entityName: String {

        return entity.name!
    }

    static func count(in context: NSManagedObjectContext, configure: (NSFetchRequest<Self>) -> Void = { _ in }) -> Int {
        let request = NSFetchRequest<Self>(entityName: entityName)
        configure(request)

        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
}
