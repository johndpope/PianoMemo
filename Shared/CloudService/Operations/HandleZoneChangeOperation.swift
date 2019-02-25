//
//  HandlerZoneChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 24/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData
import UIKit

/// ZoneChangeProvider로부터 받은 정보를 이용해 로컬 데이터베이스를 갱신한다.
class HandleZoneChangeOperation: Operation {
    private weak var recordHandler: RecordHandlable?
    private weak var errorHandler: FetchErrorHandlable?
    private let scope: CKDatabase.Scope
    private let needBypass: Bool
    private var completion: ((Bool) -> Void)?
    private var zoneChangeProvider: ZoneChangeProvider? {
        if let provider = dependencies
            .filter({$0 is ZoneChangeProvider})
            .first as? ZoneChangeProvider {
            return provider
        }
        return nil
    }

    /// HandleZoneChangeOperation를 생성한다.
    ///
    /// - Parameters:
    ///   - scope: 변경사항이 일어난 데이터베이스를 표현
    ///   - recordHandler: 실제로 데이터베이스를 조작하는 객체를 표현
    ///   - errorHandler: 에러를 처리하는 객체를 표현
    ///   - needByPass: 노트 리스트를 건너뛰어야하는지 여부를 표현
    ///   - completion: completion handler를 표현
    init(scope: CKDatabase.Scope,
         recordHandler: RecordHandlable,
         errorHandler: FetchErrorHandlable,
         needByPass: Bool = false,
         completion: @escaping (Bool) -> Void) {

        self.scope = scope
        self.recordHandler = recordHandler
        self.errorHandler = errorHandler
        self.needBypass = needByPass
        self.completion = completion
        super.init()
    }

    override func main() {
        guard let changeProvider = zoneChangeProvider,
            let recordHandler = recordHandler,
            let errorHandler = errorHandler else { return }

        // opeation chain 중에 에러가 발생하면 여기서 처리한다.
        if let error = changeProvider.error {
            errorHandler.handleError(error: error) { [weak self] in
                guard let self = self else { return }
                self.executeCompletion()
                return
            }
        }

        // 새로 생성되었거나 갱신된 레코드들을 처리한다.
        changeProvider.newRecords.forEach { wrapper in
            let isMine = wrapper.0
            let record = wrapper.1

            recordHandler.createOrUpdate(record: record, isMine: isMine) { _ in
                self.popDetailIfNeeded(recordHandler: recordHandler, recordID: record.recordID)
            }
        }
        // 삭제된 레코드들을 처리한다.
        changeProvider.removedReocrdIDs.forEach { recordID in
            recordHandler.remove(recordID: recordID) { _ in
                self.popDetailIfNeeded(recordHandler: recordHandler, recordID: recordID)
            }
        }

        executeCompletion()
        // 리스트를 건너뛰어야 할 경우 노티를 발생시킨다.
        if needBypass {
            NotificationCenter.default.post(name: .bypassList, object: nil)
        }
    }
}

extension HandleZoneChangeOperation {
    /// 사용자가 보고 있는 노트가 삭제된 경우, pop 노티를 발생시킨다.
    /// 사용자가 보고 있는 노트가 변경된 경우, merge 노티를 발생시킨다.
    private func popDetailIfNeeded(recordHandler: RecordHandlable, recordID: CKRecord.ID) {
        recordHandler.backgroundContext.performAndWait {
            guard let editing = EditingTracker.shared.editingNote,
                let note = recordHandler.backgroundContext.object(with: editing.objectID) as? Note,
                note.recordID == recordID else { return }

            if note.isRemoved || note.markedForDeletionDate != nil {
                NotificationCenter.default.post(name: .popDetail, object: nil)
            } else {
                guard let content = note.content else { return }
                let dict = ["newContent": content]
                NotificationCenter.default.post(
                    name: .resolveContent,
                    object: nil,
                    userInfo: dict
                )
            }
        }
    }

    /// 로컬 데이터베이스 갱신이 끝나면 노티를 발생시킨다.
    private func executeCompletion() {
        if let completion = completion {
            completion(true)
            self.completion = nil
            if self.scope == .private {
                NotificationCenter.default.post(name: .didFinishHandleZoneChange, object: nil)
            }
        }
    }
}
