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
    private let resultsController: NSFetchedResultsController<Note>
    private let completion: () -> Void
    private let noteCollectionState: NoteCollectionViewController.NoteCollectionState
    private var keyword = ""

    private var context: NSManagedObjectContext {
        return resultsController.managedObjectContext
    }

    init(controller: NSFetchedResultsController<Note>,
         noteCollectionState: NoteCollectionViewController.NoteCollectionState,
         completion: @escaping () -> Void) {
        self.resultsController = controller
        self.noteCollectionState = noteCollectionState
        self.completion = completion
        super.init()
    }

    func setKeyword(_ keyword: String) {
        self.keyword = keyword
    }

    override func main() {
        if isCancelled {
            print("cancelled")
            state = .Finished
            return
        }
        context.perform { [weak self] in
            guard let self = self else { return }
            if self.isCancelled {
                self.state = .Finished
                return
            }
            do {
                try self.context.setQueryGenerationFrom(NSQueryGenerationToken.current)
                NSFetchedResultsController<Note>.deleteCache(withName: self.noteCollectionState.cache)
                if self.keyword.count == 0 {
                    self.resultsController.fetchRequest.predicate = self.noteCollectionState.noteRequest.predicate
                } else {
                    self.resultsController.fetchRequest.predicate = self.predicate(with: self.keyword)
                }
                if self.isCancelled {
                    self.state = .Finished
                    return
                }
                try self.resultsController.performFetch()
                NSFetchedResultsController<Note>.deleteCache(withName: self.noteCollectionState.cache)
                if self.isCancelled {
                    self.state = .Finished
                    return
                }
                OperationQueue.main.addOperation {
                    self.completion()
                    self.state = .Finished
                }
            } catch {
                self.state = .Finished
            }
        }
    }
}

extension FilterNoteOperation {
    private func predicate(with keyword: String) -> NSPredicate {
        var predicates: [NSPredicate] = []
        let set = Set(keyword.tokenized)
        let tokenizedPredicates = set.count > 0 ?
            set.map { NSPredicate(format: "content contains[cd] %@", $0) }
            : [NSPredicate(value: false)]

        predicates.append(noteCollectionState.noteRequest.predicate ?? NSPredicate(value: true))
        predicates.append(contentsOf: tokenizedPredicates)
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
