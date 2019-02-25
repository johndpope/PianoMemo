//
//  NoteHandler.swift
//  Piano
//
//  Created by hoemoon on 25/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

class NoteHandler: NSObject, NoteHandlable {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}
