//
//  CloudToken.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

/// [String : CKServerChangeToken] with UserDefaults.
internal class CloudToken: NSObject, NSCoding {
    
    internal var byZoneID = [String : CKServerChangeToken]() {
        didSet {
            let cloudTokenData = NSKeyedArchiver.archivedData(withRootObject: self)
            UserDefaults.standard.set(cloudTokenData, forKey: KEY_TOKEN)
        }
    }
    
    internal override init() {
        super.init()
    }
    
    internal func encode(with aCoder: NSCoder) {
        aCoder.encode(byZoneID, forKey: KEY_TOKEN)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        if let decodedTokens = aDecoder.decodeObject(forKey: KEY_TOKEN) as? [String: CKServerChangeToken] {
            byZoneID = decodedTokens
        }
    }
    
    internal static func loadFromUserDefaults() -> CloudToken {
        if let data = UserDefaults.standard.data(forKey: KEY_TOKEN), let cloudToken = NSKeyedUnarchiver.unarchiveObject(with: data) as? CloudToken {
            return cloudToken
        }
        return CloudToken()
    }
    
}
