//
//  LongLived.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

/// fetchLongLivedOperation.
internal class LongLived {
    
    private let container: Container
    
    internal init(with container: Container) {
        self.container = container
    }
    
    /// LongLivedOperationIDs가 있는지 검사하여 Cloud에 re-upload를 진행한다.
    internal func operate() {
        container.cloud.fetchAllLongLivedOperationIDs { operationIDs, error in
            guard error == nil, let operationIDs = operationIDs else {return}
            operationIDs.forEach { id in
                self.container.cloud.fetchLongLivedOperation(withID: id) { operation, error in
                    guard error == nil, let operation = operation else {return}
                    self.container.cloud.add(operation)
                }
            }
        }
    }
    
}
