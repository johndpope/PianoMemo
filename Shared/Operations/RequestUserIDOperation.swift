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
        guard UserDefaults.getUserIdentity() == nil else {
            state = .Finished
            return
        }

        container.fetchUserRecordID { [weak self] recordID, error in
            guard let recordID = recordID else {
                self?.state = .Finished
                return
            }
            self?.container.discoverUserIdentity(withUserRecordID: recordID) {
                identity, error in
                if error == nil {
                    UserDefaults.setUserIdentity(identity: identity)
                } else {
                    print(error!)
                }
                self?.state = .Finished
            }
        }

    }
}
