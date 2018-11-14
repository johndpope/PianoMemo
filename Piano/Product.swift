//
//  Product.swift
//  Piano
//
//  Created by hoemoon on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import StoreKit

struct Product {
    let productIdentifier: String
    let localizedTitle: String
    let localizedDescription: String
    let price: NSDecimalNumber

    var isPurchased: Bool

    init(skProduct: SKProduct) {
        self.productIdentifier = skProduct.productIdentifier
        self.localizedTitle = skProduct.localizedTitle
        self.localizedDescription = skProduct.localizedDescription
        self.price = skProduct.price
        self.isPurchased = false
    }
}
