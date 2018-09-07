//
//  String.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 10..
//

internal extension String {
    
    /// 해당 string과 동일한 id의 LocalizedString을 반환한다.
    internal var loc: String {
        if let bundle_iOS = Bundle(identifier: "com.piano.Cloud-iOS") {
            return NSLocalizedString(self, tableName: nil, bundle: bundle_iOS, value: self, comment: self)
        }
        if let bundle_Mac = Bundle(identifier: "com.piano.Cloud-Mac") {
            return NSLocalizedString(self, tableName: nil, bundle: bundle_Mac, value: self, comment: self)
        }
        return ""
    }
    
}
