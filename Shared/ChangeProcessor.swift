//
//  ChangeProcessor.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol ChangeProcessor {
    func setup(for context: ChangeProcessorContext)
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext)
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>?
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> Void)
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext)
}

protocol ChangeProcessorContext: class {
    var context: NSManagedObjectContext { get }
    var remote: RemoteProvider { get }
    func perform(_ block: @escaping () -> Void)
    func delayedSaveOrRollback()
}

protocol ElementChangeProcessor: ChangeProcessor {
    associatedtype Element: NSManagedObject, Managed

    var elementsInProgress: InProgressTracker<Element> { get }

    func processChangedLocalElements(_ elements: [Element], in context: ChangeProcessorContext)

    var predicateForLocallyTrackedElements: NSPredicate { get }
}

extension ElementChangeProcessor {
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        let matching = objects.filter(entityAndPredicateForLocallyTrackedObjects(in: context)!)
        if let elements = matching as? [Element] {
            let newElements = elementsInProgress.objectsToProgress(from: elements)
            processChangedLocalElements(newElements, in: context)
        }
    }

    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        let predicate = predicateForLocallyTrackedElements
        return EntityAndPredicate(entity: Element.entity(), predicate: predicate)
    }
}
