//
//  ErrorHandleable.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 6..
//

import CloudKit

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

internal protocol ErrorHandleable: class {
    var container: Container {get set}
    var errorBlock: ((Error?) -> ())? {get set}
}

internal extension ErrorHandleable where Self: Subscription {
    
    internal func errorHandle(subscription error: Error?) {
        guard let error = error as? CKError else {return}
        switch error.code {
        case .zoneNotFound: SyncData(with: container).operate()
        case .operationCancelled: break
        default: break
        }
    }
}

internal extension ErrorHandleable where Self: Download {
    
    internal func errorHandle(fetch error: Error, _ database: CKDatabase) {
        guard let error = error as? CKError else {return}
        switch error.code {
        case .userDeletedZone:
            #if os(iOS)
            let alert = UIAlertController(title: "purge_title".loc, message: "purge_msg".loc, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".loc, style: .cancel))
            alert.addAction(UIAlertAction(title: "apply".loc, style: .default) { _ in self.purge.operate()})
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
            #elseif os(OSX)
            // TODO:...
            #endif
        case .changeTokenExpired:
            if database.databaseScope == .private {
                token.byZoneID[PRIVATE_DB_ID] = nil
                zoneOperation(database)
            } else {
                token.byZoneID[DATABASE_DB_ID] = nil
                token.byZoneID[SHARED_DB_ID] = nil
                dbOperation(database)
            }
        default: break
        }
    }
    
}

internal extension ErrorHandleable where Self: SyncData {
    
    internal func errorHandle(observer error: Error?) {
        guard let error = error as? CKError else {return}
        switch error.code {
        case .unknownItem:
            let sync = SyncData(with: container)
            sync.remakeIfNeeded = true
            sync.operate()
        default: break
        }
    }
    
}

internal extension ErrorHandleable where Self: Upload {
    
    internal func errorHandle(observer error: Error?) {
        guard let error = error as? CKError else {return}
        switch error.code {
        case .zoneNotFound: SyncData(with: container).operate()
        case .operationCancelled: break
        case .serverRecordChanged: conflict(error)
        default: break
        }
    }
    
    private func conflict(_ error: CKError) {
        guard let ancestorRecord = error.ancestorRecord,
            let serverRecord = error.serverRecord, let clientRecord = error.clientRecord else {return}
        guard let context = usingContext else {return}
        ancestorRecord.setValue(oldContent, forKey: "content")
        serverRecord.syncMetaData(using: context)
        Converter().resolve(conflict: ConflictRecord(ancestor: ancestorRecord, server: serverRecord, client: clientRecord), context: context)
    }
}

