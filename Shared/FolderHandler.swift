//
//  FolderHandler.swift
//  Piano
//
//  Created by hoemoon on 10/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

protocol FolderHandlable: class {
    var context: NSManagedObjectContext! { get }

    func setup(context: NSManagedObjectContext)

    func create(name: String, completion: ((Folder?) -> Void)?)
    func update(folder: Folder, newName: String, completion: ChangeCompletion)
    func remove(folders: [Folder], completion: ChangeCompletion)

    func add(notes: [Note], to: Folder, completion: ChangeCompletion)
    func remove(notes: [Note], from: Folder, completion: ChangeCompletion)
    func move(notes: [Note], from: Folder, to: Folder, completion: ChangeCompletion)
}

class FolderHandler: NSObject, FolderHandlable {
    var context: NSManagedObjectContext!

    func setup(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension FolderHandlable {
    func create(name: String, completion: ((Folder?) -> Void)?) {
        context.perform { [weak self] in
            guard let self = self else { return }
            let folder = Folder.insert(into: self.context)
            folder.name = name
            if self.context.saveOrRollback() {
                completion?(folder)
            } else {
                completion?(nil)
            }
        }
    }

    func update(folder: Folder, newName: String, completion: ChangeCompletion) {
        context.perform { [weak self] in
            guard let self = self else { return }
            folder.name = newName
            completion?(self.context.saveOrRollback())
        }
    }

    func remove(folders: [Folder], completion: ChangeCompletion) {
        context.perform { [weak self] in
            guard let self = self else { return }
            folders.forEach {
                self.context.delete($0)
            }
            completion?(self.context.saveOrRollback())
        }
    }

    func add(notes: [Note], to folder: Folder, completion: ChangeCompletion) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
        }
    }

    func remove(notes: [Note], from folder: Folder, completion: ChangeCompletion) {

    }

    func move(notes: [Note], from origin: Folder, to new: Folder, completion: ChangeCompletion) {

    }
}
