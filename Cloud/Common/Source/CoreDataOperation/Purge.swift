//
//  Purge.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 5..
//

import CoreData

internal class Purge {
    
    private let container: Container
    
    internal init(with container: Container) {
        self.container = container
    }
    
    internal func operate() {
        let context = container.coreData.viewContext
        context.name = FETCH_CONTEXT
        for entity in self.container.coreData.managedObjectModel.entities where entity.isCloudable {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            request.includesPropertyValues = false
            guard let objects = try? context.fetch(request) as? [NSManagedObject], let strongObjects = objects else {continue}
            strongObjects.forEach {context.delete($0)}
        }
        if context.hasChanges {try? context.save()}
        context.name = nil
    }
    
}
