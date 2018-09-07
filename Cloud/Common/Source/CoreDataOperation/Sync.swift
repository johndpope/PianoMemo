//
//  Sync.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//
import CoreData

/// Local data를 Cloud를 전체 upload하는 기능.
internal class Sync: Uploadable, ErrorHandleable {
    
    internal var container: Container
    internal var recordsToSave = [RecordCache]()
    internal var recordIDsToDelete = [RecordCache]()
    internal var errorBlock: ((Error?) -> ())?
    
    private var subscription: Subscription!
    private var zone: Zone!
    
    internal init(with container: Container) {
        self.container = container
        subscription = Subscription(with: container)
        zone = Zone(with: container)
    }
    
    internal func operate() {
        zone.operate {
            self.subscription.operate {
                self.cache(self.fetchedObjects())
                self.upload()
            }
        }
    }
    
}

private extension Sync {
    
    private func fetchedObjects() -> Set<NSManagedObject> {
        var insertedObjects = Set<NSManagedObject>()
        for entity in container.coreData.managedObjectModel.entities where entity.isCloudable {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            guard let objects = try? container.coreData.viewContext.fetch(request) as? [NSManagedObject], let strongObjects = objects else {continue}
            insertedObjects.formUnion(strongObjects)
        }
        return insertedObjects
    }
    
}
