//
//  ParsedReceipt.swift
//  Piano
//
//  Created by hoemoon on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

/// 영수증을 표현한다.
struct ParsedReceipt {
    let bundleIdentifier: String?
    let bundleIdData: NSData?
    let appVersion: String?
    let opaqueValue: NSData?
    let sha1Hash: NSData?
    let inAppPurchaseReceipts: [ParsedInAppPurchaseReceipt]?
    let originalAppVersion: String?
    let receiptCreationDate: Date?
    let expirationDate: Date?
}
