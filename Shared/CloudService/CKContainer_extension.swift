//
//  CKContainer_extension.swift
//  Piano
//
//  Created by 박주혁 on 07/03/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CloudKit

extension CKContainer {
    /// ver2.0 이전 버젼에서 로컬에 저장된 토큰 가져오는 로직
    public static func CloudServicetokenMigration() {
        
        //데이터 베이스 Subscription 여부
        //UserDefaults.standard.set(newValue, forKey: "\(self.databaseScope.rawValue)DatabaseSubscribed")
        //데이터 베이스 ServerChangeToken
        //RecordZone ChangeToken
    }
    
    public func checkAccountStatus()  {
        self.accountStatus { (status, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            switch status {
            case .couldNotDetermine:
                print("couldNotDetermine")
            case .available:
                print("available")
            case .restricted:
                print("restricted")
            case .noAccount:
                print("noAccount")
            }
        }
    }
}
