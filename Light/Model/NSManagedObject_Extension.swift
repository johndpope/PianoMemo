//
//  NSManagedObject_Extension.swift
//  Emo
//
//  Created by Kevin Kim on 2018. 8. 25..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    internal func saveIfNeeded() {
        guard let managedContext = managedObjectContext else { return }
        if managedContext.hasChanges {
            do {
                try managedContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
