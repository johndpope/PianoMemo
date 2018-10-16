//
//  FetchNoteOperation.swift
//  Light
//
//  Created by hoemoon on 03/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData

class FetchNoteOperation: Operation {
    let resultsController: NSFetchedResultsController<Note>
    let completion: () -> Void

    init(controller: NSFetchedResultsController<Note>,
         completion: @escaping () -> Void) {
        self.resultsController = controller
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
        if isCancelled { return }
        do {
            if isCancelled { return }
            let fetched = try resultsController.managedObjectContext.fetch(resultsController.fetchRequest)
            guard fetched != resultsController.fetchedObjects else {
                return
            }
            if isCancelled { return }
            
            resultsController.managedObjectContext.performAndWait{ [weak self] in
                guard let self = self else { return }
                do {
                    try self.resultsController.performFetch()
                    completion()
                } catch {
                    print(error)
                }
            }
        } catch {
            print("FetchNoteOperation main() error: \(error.localizedDescription)")
        }
    }
}
