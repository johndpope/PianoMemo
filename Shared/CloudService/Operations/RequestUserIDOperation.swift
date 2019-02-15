//
//  RequestUserIDOperation.swift
//  Piano
//
//  Created by hoemoon on 13/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

class FetchUserIDOperation: AsyncOperation {
    private let container: CKContainer
    private let completion: (String?) -> Void

    init(container: CKContainer, completion: @escaping (String?) -> Void) {
        self.container = container
        self.completion = completion
    }

    override func main() {
        container.fetchUserRecordID { [weak self] recordID, _ in
            guard let self = self else { return }
            switch recordID?.recordName {
            case .some(let identifier):
                self.completion(identifier)
                self.state = .Finished
            case .none:
                self.completion(nil)
                self.state = .Finished
            }
        }
    }
}
