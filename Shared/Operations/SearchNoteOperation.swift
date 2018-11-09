//
//  SearchNoteOperation.swift
//  Light
//
//  Created by hoemoon on 03/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData

class SearchNoteOperation: Operation {
    let resultsController: NSFetchedResultsController<Note>
    let context: NSManagedObjectContext
    let completion: ([Note]) -> Void

    init(controller: NSFetchedResultsController<Note>,
         context: NSManagedObjectContext,
         completion: @escaping ([Note]) -> Void) {

        self.resultsController = controller
        self.context = context
        self.completion = completion
        super.init()
    }

    func setRequest(keyword: String, tags: String) {
        var predicates: [NSPredicate] = []
        
        let notRemovedPredicate = NSPredicate(format: "isRemoved == false")

        let tokenizedPredicates = Set(keyword.tokenized)
            .map { NSPredicate(format: "content contains[cd] %@", $0) }
        
        let tagsPredicates = Set(tags).map { NSPredicate(format: "tags contains[cd] %@", String($0))}

        if Set(tags).count > 0 {
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: tagsPredicates))
        }
        predicates.append(notRemovedPredicate)
        predicates.append(contentsOf: tokenizedPredicates)

        resultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    override func main() {
        if isCancelled {
            print("cancelled")
            return
        }
        context.performAndWait {
            [weak self] in
            guard let self = self  else { return }
            do {
                if isCancelled {
                    return
                }
                try self.resultsController.performFetch()
                if let fetched = resultsController.fetchedObjects, fetched.count > 0 {
                    completion(fetched)
                }
            } catch {
                print(error)
            }
        }
    }
}
