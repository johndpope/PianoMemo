//
//  PushNotesOperation.swift
//  Piano
//
//  Created by hoemoon on 19/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import Kuery

class PushNotesOperation: AsyncOperation {
    let context: NSManagedObjectContext

    private var migrationStateProvider: MigrationStateProvider? {
        if let provider = dependencies
            .filter({$0 is MigrationStateProvider})
            .first as? MigrationStateProvider {
            return provider
        }
        return nil
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }

    override func main() {
        guard let provider = migrationStateProvider else { state = .Finished; return }
        if !provider.didMigration {
            state = .Finished
            return
        }

        context.performAndWait {
            do {
                let notes = try Query(Note.self).execute()
                if notes.count == 0 {
                    self.state = .Finished
                    return
                }
                notes.forEach {
                    $0.markUploadReserved()
                }
                context.saveOrRollback()
                state = .Finished
                NotificationCenter.default.post(name: .didFinishMigration, object: nil)
            } catch {
                print(error)
                self.state = .Finished
            }
        }
    }
}
