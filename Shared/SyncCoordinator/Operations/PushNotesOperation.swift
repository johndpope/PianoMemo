//
//  PushNotesOperation.swift
//  Piano
//
//  Created by hoemoon on 19/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

/// 마이그레이션 과정 중에서 변경된 노트를 클라우드에 업로드 합니다.
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
                let request: NSFetchRequest<Note> = Note.fetchRequest()
                request.predicate = NSPredicate(value: true)
                let notes = try context.fetch(request)
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
