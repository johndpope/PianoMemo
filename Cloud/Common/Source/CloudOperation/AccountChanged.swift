//
//  AccountChanged.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 6..
//

/// Observer for CKAccountChanged.
internal class AccountChanged {
    
    private let container: Container
    private var userID: CKRecordID? {
        guard let userData = UserDefaults.standard.data(forKey: USER_KEY) else {return nil}
        return NSKeyedUnarchiver.unarchiveObject(with: userData) as? CKRecordID
    }
    
    internal init(with container: Container) {
        self.container = container
    }
    
    private var completionBlock: (() -> ())?
    @objc private func action(accountChanged: Notification) {completionBlock?()}
    /**
     NSNotification.Name.CKAccountChanged에 대한 addObserver를 진행한다.
     - Parameter completion: Observer가 notification 되었을때 호출된다.
     */
    internal func addObserver(_ completion: @escaping (() -> ())) {
        completionBlock = completion
        NotificationCenter.default.addObserver(self, selector: #selector(action(accountChanged:)), name: .CKAccountChanged, object: nil)
    }
    
    internal func requestUserInfo(_ completion: @escaping (() -> ())) {
        container.cloud.fetchUserRecordID() { recordID, error in
            guard error == nil, let recordID = recordID else {return}
            if self.userID != recordID {
                let recordData = NSKeyedArchiver.archivedData(withRootObject: recordID)
                UserDefaults.standard.set(recordData, forKey: USER_KEY)
                completion()
            }
        }
    }
    
}
