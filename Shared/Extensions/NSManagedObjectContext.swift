//
//  NSManagedObjectContext.swift
//  Piano
//
//  Created by hoemoon on 05/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {

    internal func saveIfNeeded() {
        guard hasChanges else { return }

        do {
             try save()
        } catch {
            print("컨텍스트 저장하다 에러: \(error)")
        }
    }
}

