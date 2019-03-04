//
//  RequestUserIDOperation.swift
//  Piano
//
//  Created by hoemoon on 13/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

/// cloudkit에서 제공하는 사용자 고유의 식별자를 요청하는 Operation.
/// completion handler로 식별자를 받을 수 있습니다.
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
