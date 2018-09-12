//
//  ContextSave.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CoreData

/// CoreData의 persistent save를 감지해서 Cloud에 upload해주는 기능.
public class Upload: Uploadable, ErrorHandleable {
    
    internal var container: Container
    internal var recordsToSave = [RecordCache]()
    internal var recordIDsToDelete = [RecordCache]()
    internal var errorBlock: ((Error?) -> ())?
    
    public var didSaveBlock: (() -> ())?
    
    internal init(with container: Container) {
        self.container = container
    }
    
    /// CoreData의 willSave/DidSave에 대한 observer를 add한다.
    internal func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(willSave(_:)), name: .NSManagedObjectContextWillSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
        print("added")
    }
    
    /// CoreData의 willSave/DidSave에 대한 observer를 remove한다.
    internal func removeObserver() {
        NotificationCenter.default.removeObserver(self)
        print("removed")
    }
    
    /// Context의 cache를 기준으로 upload를 진행한다. (Have to call this before 'context.save()')
    public func operate() {
        manualSave(using: container.coreData.viewContext)
    }
    
}

private extension Upload {
    
    @objc private func willSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else {return}
        guard context.name == nil || context.name != FETCH_CONTEXT else {return}
        cache(context.insertedObjects, context.updatedObjects, context.deletedObjects)
    }
    
    @objc private func didSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else {return}
        guard context.name == nil || context.name != FETCH_CONTEXT else {return}
        errorBlock = {self.errorHandle(observer: $0)}
        context.name = nil
        didSaveBlock?()
        upload()
    }
    
    private func manualSave(using context: NSManagedObjectContext) {
        guard context.name == nil || context.name != FETCH_CONTEXT else {return}
        cache(context.insertedObjects, context.updatedObjects, context.deletedObjects)
        errorBlock = {self.errorHandle(observer: $0)}
        context.name = nil
        didSaveBlock?()
        upload()
    }
    
}
