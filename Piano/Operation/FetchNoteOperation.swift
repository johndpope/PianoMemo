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
    let completion: ([Note]) -> Void

    init(controller: NSFetchedResultsController<Note>,
         completion: @escaping ([Note]) -> Void) {
        self.resultsController = controller
        self.completion = completion
        super.init()
    }

    func setRequest(with text: String) {
        resultsController.fetchRequest.predicate = text.predicate(fieldName: "content")
    }

    override func main() {
        if isCancelled { return }
        do {
            if isCancelled { return }
            try resultsController.performFetch()
            if isCancelled { return }
            if let objects = resultsController.fetchedObjects,
                objects.count > 0 {
                completion(objects)
            }
        } catch {
            completion([])
            print("FetchNoteOperation main() error: \(error.localizedDescription)")
        }
    }
}
