//
// Created by 김범수 on 2018. 4. 19..
// Copyright (c) 2018 piano. All rights reserved.
//

/*
import CloudKit
//import RxSwift

typealias CloudSaveHandler = ((CKRecord?, Error?) -> Void)
typealias CloudDeleteHandler = ((Error?) -> Void)

class RxCloudDatabase {
    static let privateRecordZoneName = "Cloud_Memo_Zone"
    let database: CKDatabase
    var synchronizers: [String: NoteSynchronizer] = [:]

    private let saveSubject = PublishSubject<([CKRecord], CloudSaveHandler)>()
    private let deleteSubject = PublishSubject<([CKRecordID], CloudDeleteHandler)>()
    private let disposeBag = DisposeBag()

    init(database: CKDatabase) {
        self.database = database

        subscribeToObservers()
    }

    ///Subscribe to save&delete observables to perform batch operation
    private func subscribeToObservers() {
        saveSubject.window(timeSpan: 0.1, count: 1, scheduler: MainScheduler.instance)
            .flatMap{ return $0 }.asObservable()
            .subscribe(onNext: {[weak self] (recordsAndHandler) in
                self?.upload(recordsAndHandler.0, completion: recordsAndHandler.1)
            }).disposed(by: disposeBag)

        deleteSubject.window(timeSpan: 0.1, count: 1, scheduler: MainScheduler.instance)
            .flatMap { return $0 }.asObservable()
            .subscribe(onNext: { [weak self] (recordIDs, handler) in
                self?.delete(recordIDs, completion: handler)
            }).disposed(by: disposeBag)

    }

    private func upload(_ records: [CKRecord], completion handler: @escaping CloudSaveHandler) {

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: [])
        operation.modifyRecordsCompletionBlock = {[weak self] savedRecords, _, error in
            guard error == nil else {
                handler(nil, error)
                return
            }

            self?.syncMetaDatas(records: savedRecords ?? [])
            handler(nil, nil)
        }
        operation.qualityOfService = .utility

        database.add(operation)
    }

    private func delete(_ recordIDs: [CKRecordID], completion handler: @escaping CloudDeleteHandler) {

        let operation = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: recordIDs)
        operation.modifyRecordsCompletionBlock = { (_, _, error) in
            guard error == nil else {
                handler(error)
                return
            }
            handler(nil)
        }
        operation.qualityOfService = .utility

        database.add(operation)
    }

    func upload(record: CKRecord, ancestorRecord: CKRecord? = nil, completion: @escaping CloudSaveHandler) {
        let cloudCompletion: CloudSaveHandler = { [weak self] conflicted, error in
            guard error == nil else {
                guard let ckError = error as? CKError else {return completion(nil, error)}

                if ckError.isZoneNotFound() && self?.database.databaseScope == .private {
                    let zone = CKRecordZone(zoneName: RxCloudDatabase.privateRecordZoneName)
                    self?.createZoneWithID(zoneID: zone.zoneID) { error in
                        guard error == nil else {return completion(nil, error)}
                        self?.upload(record: record, ancestorRecord: ancestorRecord, completion: completion)
                    }
                    return
                } else {
                    let (wrappedAncestor, wrappedClient, wrappedServer) = ckError.getMergeRecords()

                    guard let clientRecord = wrappedClient,
                            let serverRecord = wrappedServer,
                            let ancestorRecord = ancestorRecord ?? wrappedAncestor ?? nil else {return completion(nil,error)}

                    
                    self?.merge(ancestor: ancestorRecord, myRecord: clientRecord, serverRecord: serverRecord) { merged in
                        if merged {
                            self?.upload(record: serverRecord) { newRecord, error in
                                completion(newRecord, error)
                            }
                        } else {
                            completion(serverRecord, nil)
                        }
                    }

                }
                return
            }

            completion(nil,nil)
        }
        saveSubject.onNext(([record],cloudCompletion))
    }

    /// record: array
    func upload(records: [CKRecord], completion: @escaping CloudSaveHandler) {
        saveSubject.on(.next((records, completion)))
    }

    /// recordID: array
    func delete(recordIDs: [CKRecordID], completion: @escaping CloudDeleteHandler) {
        deleteSubject.on(.next((recordIDs, completion)))
    }

    /// recordID: array
    func load(recordIDs: [CKRecordID], completion: @escaping (([CKRecordID: CKRecord]?,Error?) -> Void)) {
        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = { recordDic, error in
            guard error == nil else { return completion(nil, error)}
            completion(recordDic,nil)
        }
        operation.qualityOfService = .utility

        database.add(operation)
    }

    /**
       This method creates custom Zone with specific identifier
       in this class.
      */
    func createZoneWithID(zoneID: CKRecordZoneID, completion: @escaping ((Error?) -> Void)) {
        let recordZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [])

        operation.modifyRecordZonesCompletionBlock = { (_, _, error) in
            completion(error)
        }

        operation.qualityOfService = .utility

        database.add(operation)
    }

    func register(synchronizer: NoteSynchronizer) {
        synchronizers[synchronizer.recordName] = synchronizer
    }

    func unregister(synchronizer: NoteSynchronizer) {
        synchronizers.removeValue(forKey: synchronizer.recordName)
    }
}
*/
