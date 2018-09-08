//
//  Modify.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 5..
//

import CoreData

/// Fetch된 내역을 local에 modify하는 기능.
internal class Modify {
    
    private let container: Container
    
    internal init(with container: Container) {
        self.container = container
    }
    
    internal func operate(_ record: CKRecord, _ context: NSManagedObjectContext) {
        fetch(with: record, using: context)
    }
    
    internal func operate(forReference record: [CKRecord], _ context: NSManagedObjectContext) {
        record.forEach {fetch(with: $0, using: context)}
        if context.hasChanges {try? context.save()}
    }
    
}

private extension Modify {
    
    private func fetch(with record: CKRecord, using context: NSManagedObjectContext) {
        guard record.recordType != SHARE_RECORD_TYPE else {return}
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: record.recordType)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "\(KEY_RECORD_NAME) == %@", record.recordID.recordName)
        if let object = try? context.fetch(request).first as? NSManagedObject, let strongObject = object {
            modify(from: record, to: strongObject)
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: record.recordType, in: context) else {return}
            modify(from: record, to: NSManagedObject(entity: entity, insertInto: context))
        }
    }
    
    private func modify(from record: CKRecord, to object: NSManagedObject) {
        object.setValue(record.metadata, forKey: KEY_RECORD_DATA)
        object.setValue(record.recordID.recordName, forKey: KEY_RECORD_NAME)
        let converter = Converter()
        converter.record(toObject: ManagedUnit(record: record, object: object))
    }
    
}
