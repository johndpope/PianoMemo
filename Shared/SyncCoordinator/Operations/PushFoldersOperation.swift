//
//  PushFoldersOperation.swift
//  Piano
//
//  Created by hoemoon on 19/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import Kuery

class PushFoldersOperation: AsyncOperation, MigrationStateProvider {
    let context: NSManagedObjectContext
    let remote: RemoteProvider

    var didMigration = false

    private var migrationStateProvider: MigrationStateProvider? {
        if let provider = dependencies
            .filter({$0 is MigrationStateProvider})
            .first as? MigrationStateProvider {
            return provider
        }
        return nil
    }

    init(context: NSManagedObjectContext, remote: RemoteProvider) {
        self.context = context
        self.remote = remote
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
                let folders = try Query(Folder.self).execute()
                if folders.count == 0 {
                    state = .Finished
                    return
                }
                remote.upload(folders, savePolicy: .ifServerRecordUnchanged) { [weak self] saved, _, _ in
                    guard let self = self else { return }
                    guard let saved = saved else { self.state = .Finished; return }
                    self.context.performAndWait {
                        for folder in folders {
                            if let record = saved.first(
                                where: { folder.modifiedAt == ($0.modifiedAtLocally as Date?) }) {
                                folder.recordID = record.recordID
                                folder.recordArchive = record.archived
                            }
                        }
                        self.didMigration = true
                        self.state = .Finished
                    }
                }
            } catch {
                print(error)
                state = .Finished
            }
        }
    }
}
