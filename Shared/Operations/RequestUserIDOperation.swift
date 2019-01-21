//
//  RequestUserIDOperation.swift
//  Piano
//
//  Created by hoemoon on 13/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import Branch

class RequestUserIDOperation: AsyncOperation {
    private let container: CKContainer

    init(container: CKContainer) {
        self.container = container
    }

    override func main() {
        guard NSUbiquitousKeyValueStore.default.string(forKey: Referral.brachUserID) == nil else {
            state = .Finished
            return
        }
        UserDefaults.standard.removeObject(forKey: Referral.shareLinkKey)

        container.fetchUserRecordID { [weak self] recordID, _ in
            guard let self = self else { return }

            switch recordID?.recordName {
            case .some(let identifier):
                NSUbiquitousKeyValueStore.default.set(
                    identifier,
                    forKey: Referral.brachUserID
                )
                self.state = .Finished
            case .none:
                let newID = UUID().uuidString
                UserDefaults.standard.set(
                    newID,
                    forKey: Referral.tempBranchID
                )
                self.state = .Finished
            }
        }
    }
}
