//
//  CloudToken.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CloudKit

/// [String : CKServerChangeToken] with UserDefaults.
internal class CloudToken: NSObject, NSCoding {
    
    internal var byZoneID = [String : CKServerChangeToken]() {
        didSet {
            let tokenData = NSKeyedArchiver.archivedData(withRootObject: self)
            UserDefaults.standard.set(tokenData, forKey: KEY_TOKEN)
        }
    }
    
    internal override init() {
        super.init()
    }
    
    internal func encode(with aCoder: NSCoder) {
        aCoder.encode(byZoneID, forKey: KEY_TOKEN)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        if let decodedByZoneID = aDecoder.decodeObject(forKey: KEY_TOKEN) as? [String : CKServerChangeToken] {
            byZoneID = decodedByZoneID
        }
    }
    
    internal static func loadFromUserDefaults() -> CloudToken {
        if let data = UserDefaults.standard.data(forKey: KEY_TOKEN) {
            if let cloudToken = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CloudToken {
                return cloudToken
            }
        }
        return CloudToken()
    }
}
