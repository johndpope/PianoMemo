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
    }
    
    /// CoreData의 willSave/DidSave에 대한 observer를 remove한다.
    internal func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     해당 context의 cache를 기준으로 upload를 진행한다.
     
     (Have to call this before 'context.save()')
     - Parameter context: Target context.
     (Default value is 'persistentContainer.viewContext')
     */
    public func operate(using context: NSManagedObjectContext?) {
        let context = (context != nil) ? context : container.coreData.viewContext
        manualSave(using: context!)
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
        print((context.insertedObjects, context.updatedObjects, context.deletedObjects))
        cache(context.insertedObjects, context.updatedObjects, context.deletedObjects)
        errorBlock = {self.errorHandle(observer: $0)}
        context.name = nil
        didSaveBlock?()
        upload()
    }
    
}
