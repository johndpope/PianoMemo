//
//  FilterNoteOperation.swift
//  Light
//
//  Created by hoemoon on 03/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData

class FilterNoteOperation: AsyncOperation {
    private let context: NSManagedObjectContext
    private let resultsController: NSFetchedResultsController<Note>
    private let completion: () -> Void
    private var tags = ""

    init(context: NSManagedObjectContext,
         controller: NSFetchedResultsController<Note>,
         completion: @escaping () -> Void) {
        self.context = context
        self.resultsController = controller
        self.completion = completion
        super.init()
    }

    func setTags(_ tags: String) {
        self.tags = tags
        var predicates: [NSPredicate] = []

        let tagsPredicates = Set(tags).map { NSPredicate(format: "tags contains[cd] %@", String($0))}

        if Set(tags).count > 0 {
            predicates.append(NSCompoundPredicate(andPredicateWithSubpredicates: tagsPredicates))
        }
        predicates.append(Note.predicateForMaster)

        resultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    override func main() {
        context.performAndWait {
            do {
                NSFetchedResultsController<Note>.deleteCache(withName: "Note")
                try context.setQueryGenerationFrom(NSQueryGenerationToken.current)
                try self.resultsController.performFetch()
                NSFetchedResultsController<Note>.deleteCache(withName: "Note")
                completion()
                state = .Finished
            } catch {
                print(error)
            }
        }
    }
}
