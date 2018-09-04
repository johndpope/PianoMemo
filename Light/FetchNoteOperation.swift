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
    let noteFetchRequest: NSFetchRequest<Note>
    let resultsController: NSFetchedResultsController<Note>
    let completion: ([Note]) -> Void

    init(request: NSFetchRequest<Note>,
         controller: NSFetchedResultsController<Note>,
         completion: @escaping ([Note]) -> Void) {
        self.noteFetchRequest = request
        self.resultsController = controller
        self.completion = completion
        super.init()
    }

    func setRequest(with text: String) {
        noteFetchRequest.predicate = text.predicate(fieldName: "content")
    }

    override func main() {
        let oldObjects = resultsController.fetchedObjects ?? []
        if isCancelled { return }
        do {
            if isCancelled { return }
            try resultsController.performFetch()
            let newObjects = resultsController.fetchedObjects ?? []
            if isCancelled { return }

            if oldObjects.count == 0 || oldObjects != newObjects {
                completion(newObjects)
            }
//            if let notes = resultsController.fetchedObjects {
//                completion(notes)
//            }
        } catch {
            // TODO:
        }
    }
}
