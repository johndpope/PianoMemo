//
//  FolderHandler.swift
//  Piano
//
//  Created by hoemoon on 10/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import Kuery

protocol FolderHandlable: class {
    var context: NSManagedObjectContext { get }

    func create(name: String, completion: ((Folder?) -> Void)?)
    func update(folder: Folder, newName: String, completion: ChangeCompletion)
    func remove(folders: [Folder], completion: ChangeCompletion)

//    func add(notes: [Note], to: Folder, completion: ChangeCompletion)
//    func remove(notes: [Note], from: Folder, completion: ChangeCompletion)
//    func move(notes: [Note], from: Folder, to: Folder, completion: ChangeCompletion)
}

class FolderHandler: NSObject, FolderHandlable {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension FolderHandlable {
    func create(name: String, completion: ((Folder?) -> Void)?) {
        context.performAndWait {
            do {
                let count = try context.count(for: Folder.listRequest)
                let folder = Folder.insert(into: context)
                folder.name = name
                folder.order = Double(count)

                context.perform {
                    if self.context.saveOrRollback() {
                        completion?(folder)
                    } else {
                        completion?(nil)
                    }
                }

            } catch {
                completion?(nil)
            }
        }
    }

    func update(folder: Folder, newName: String, completion: ChangeCompletion) {
        context.performAndWait {
            folder.name = newName
            if let notes = folder.notes {
                notes.forEach {
                    if let note = $0 as? Note {
                        note.markUploadReserved()
                    }
                }
            }
            context.perform {
                completion?(self.context.saveOrRollback())
            }
        }
    }

    func remove(folders: [Folder], completion: ChangeCompletion) {
        context.performAndWait {
            folders.forEach {
                if let notes = $0.notes {
                    notes.forEach {
                        if let note = $0 as? Note {
                            note.isRemoved = true
                            note.markUploadReserved()
                        }
                    }
                }
            }
            folders.forEach {
                $0.markForRemoteDeletion()
            }
            context.perform {
                completion?(self.context.saveOrRollback())
            }
        }
    }

//    func add(notes: [Note], to folder: Folder, completion: ChangeCompletion) {
//        context.perform { [weak self] in
//            guard let self = self else { return }
//            notes.forEach {
//                $0.folder = folder
//                folder.addToNotes($0)
//                $0.markUploadReserved()
//            }
//            completion?(self.context.saveOrRollback())
//        }
//    }

//    func remove(notes: [Note], from folder: Folder, completion: ChangeCompletion) {
//        context.perform { [weak self] in
//            guard let self = self else { return }
//            notes.forEach {
//                if folder.notes.contains($0) {
//                    folder.notes.remove($0)
//                }
//                $0.isRemoved = true
//                $0.markUploadReserved()
//            }
//            completion?(self.context.saveOrRollback())
//        }
//    }
}
