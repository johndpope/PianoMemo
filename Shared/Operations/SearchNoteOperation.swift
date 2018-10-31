//
//  SearchNoteOperation.swift
//  Light
//
//  Created by hoemoon on 03/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData

protocol FetchFlagProvider {
    var flag: UUID? { get }
}

class SearchNoteOperation: AsyncOperation, FetchFlagProvider {
    let resultsController: NSFetchedResultsController<Note>
    let context: NSManagedObjectContext
    let completion: () -> Void
    let id: UUID

    var flag: UUID?

    init(controller: NSFetchedResultsController<Note>,
         context: NSManagedObjectContext,
         completion: @escaping () -> Void,
         id: UUID) {

        self.resultsController = controller
        self.context = context
        self.completion = completion
        self.id = id
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
            guard let self = self  else { return }
            do {
                if isCancelled {
                    return
                }
                Flag.processing = true
                try self.resultsController.performFetch()
                print("did fetch")
                flag = id
                self.state = .Finished
            } catch {
                print(error)
            }
        }
    }
}

class ReloadOperation: AsyncOperation {
    private var idProvider: FetchFlagProvider? {
        if let provider = dependencies
            .filter({$0 is FetchFlagProvider})
            .first as? FetchFlagProvider {
            return provider
        }
        return nil
    }

    let id: UUID
    let action: () -> Void

    init(id: UUID, action: @escaping () -> Void) {
        self.id = id
        self.action = action
        super.init()
    }

    override func main() {
        if isCancelled {
            return
        }
        guard let idProvider = idProvider,
            let flag = idProvider.flag else { return }
        if flag == id {
            OperationQueue.main.cancelAllOperations()
            OperationQueue.main.addOperation {
                print("start reload")
                self.action()
                self.state = .Finished
                print("did reload")
//                Flag.didReload = true
            }
        }
    }
}
