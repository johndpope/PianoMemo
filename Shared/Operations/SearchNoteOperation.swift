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
    let completion: () -> Void

    init(controller: NSFetchedResultsController<Note>,
         context: NSManagedObjectContext,
         completion: @escaping () -> Void) {

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
        
        predicates.append(notRemovedPredicate)
        predicates.append(contentsOf: tokenizedPredicates)
        predicates.append(contentsOf: tagsPredicates)
        resultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    override func main() {
        if isCancelled {
            print("cancelled")
            return
        }
        context.performAndWait {
            [weak self] in
            guard let self = self else { return }
            do {
                if isCancelled {
                    return
                }
                try self.resultsController.performFetch()
                if isCancelled {
                    return
                }
            } catch {
                print(error)
            }
        }
    }
}

class ReloadOperation: Operation {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
    }

    override func main() {
        if isCancelled {
            return
        }
        self.action()
    }
}
