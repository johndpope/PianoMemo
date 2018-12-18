//
//  TextSearchOperation.swift
//  Piano
//
//  Created by hoemoon on 19/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData

class TextSearchOperation: AsyncOperation {
    private let backgroundContext: NSManagedObjectContext
    private let completion: ([Note]) -> Void
    private var keyword = ""

    init(context: NSManagedObjectContext,
         completion: @escaping ([Note]) -> Void) {

        self.backgroundContext = context
        self.completion = completion
        super.init()
    }

    override func main() {
        if isCancelled {
            print("cancelled")
            state = .Finished
            return
        }
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            do {
                if self.isCancelled {
                    self.state = .Finished
                    return
                }
                let fetched = try self.backgroundContext.fetch(self.request(with: self.keyword))
                if self.isCancelled {
                    self.state = .Finished
                    return
                }
                OperationQueue.main.addOperation {
                    self.completion(fetched)
                    self.state = .Finished
                }
            } catch {
                OperationQueue.main.addOperation {
                    self.completion([])
                    self.state = .Finished
                }
            }
        }
    }

    func setKeyword(_ keyword: String) {
        self.keyword = keyword
    }

    private func request(with keyword: String) -> NSFetchRequest<Note> {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let date = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.sortDescriptors = [date]

        var predicates: [NSPredicate] = []

        let notRemovedPredicate = NSPredicate(format: "isRemoved == false")
        let set = Set(keyword.tokenized)

        let tokenizedPredicates = set.count > 0 ?
            set.map { NSPredicate(format: "content contains[cd] %@", $0) }
            : [NSPredicate(value: false)]

        predicates.append(notRemovedPredicate)
        predicates.append(contentsOf: tokenizedPredicates)

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return request
    }
}
