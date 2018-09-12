//
//  Delete.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 5..
//

import CoreData

internal class Delete {
    
    private let container: Container
    
    internal init(with container: Container) {
        self.container = container
    }
    
    internal func operate(_ recordID: CKRecordID, _ context: NSManagedObjectContext) {
        for entity in self.container.coreData.managedObjectModel.entities where entity.isCloudable {
            delete(entity.name!, with: recordID, using: context)
        }
        if context.hasChanges {try? context.save()}
    }
    
}

private extension Delete {
    
    private func delete(_ entityName: String, with recordID: CKRecordID, using context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.fetchLimit = 1
        request.includesPropertyValues = false
        request.predicate = NSPredicate(format: "\(KEY_RECORD_NAME) == %@", recordID.recordName)
        guard let objects = try? context.fetch(request) as? [NSManagedObject], let strongObjects = objects else {return}
        strongObjects.forEach {context.delete($0)}
    }
    
}
