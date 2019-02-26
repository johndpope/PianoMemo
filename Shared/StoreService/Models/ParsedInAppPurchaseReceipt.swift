//
//  ParsedInAppPurchaseReceipt.swift
//  Piano
//
//  Created by hoemoon on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

/// app 내 결제 영수증을 표현한다.
struct ParsedInAppPurchaseReceipt {
    let quantity: Int?
    let productIdentifier: String?
    let transactionIdentifier: String?
    let originalTransactionIdentifier: String?
    let purchaseDate: Date?
    let originalPurchaseDate: Date?
    let subscriptionExpirationDate: Date?
    let cancellationDate: Date?
    let webOrderLineItemId: Int?
}
