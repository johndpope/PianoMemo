//
//  FilterNoteOperation.swift
//  Light
//
//  Created by hoemoon on 03/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData

class FilterNoteOperation: Operation {
    private let resultsController: NSFetchedResultsController<Note>
    private let completion: ([Note]) -> Void
    private var tags = ""

    init(controller: NSFetchedResultsController<Note>,
         completion: @escaping ([Note]) -> Void) {

        self.resultsController = controller
        self.completion = completion
        super.init()
    }

    func setTags(_ tags: String) {
        self.tags = tags
        var predicates: [NSPredicate] = []

        let notRemovedPredicate = NSPredicate(format: "isRemoved == false")

        let tagsPredicates = Set(tags).map { NSPredicate(format: "tags contains[cd] %@", String($0))}

        if Set(tags).count > 0 {
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagsPredicates))
        }
        predicates.append(notRemovedPredicate)

        resultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    override func main() {
        resultsController.managedObjectContext.performAndWait {
            do {
                try resultsController.performFetch()
                if let fetched = resultsController.fetchedObjects, fetched.count > 0 {
                    NSFetchedResultsController<Note>.deleteCache(withName: "Note")
                    completion(fetched.sorted(by: tagSortor(first:second:)))
                }
            } catch {
                print(error)
            }
        }
    }

    private func tagSortor(first: Note, second: Note) -> Bool {
        guard let firstTags = first.tags, let secondTags = second.tags else { return false }

        let filteredFirst = firstTags.splitedEmojis.filter { self.tags.splitedEmojis.contains($0) }
        let filteredSecond = secondTags.splitedEmojis.filter { self.tags.splitedEmojis.contains($0) }

        return filteredFirst.count > filteredSecond.count
    }
}
