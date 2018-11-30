//
//  Product.swift
//  Piano
//
//  Created by hoemoon on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import StoreKit

//struct Product {
//    let skProduct: SKProduct
//    let creditPrice: Int
//
//    var id: String {
//        return skProduct.productIdentifier
//    }
//
//    var title: String {
//        return skProduct.localizedTitle
//    }
//
//    var productDescription: String {
//        return skProduct.localizedDescription
//    }
//
//    var price: NSDecimalNumber {
//        return skProduct.price
//    }
//
//    init(skProduct: SKProduct, creditPrice: Int) {
//        self.skProduct = skProduct
//        self.creditPrice = creditPrice
//    }
//}

struct Product {
    let creditPrice: Int
    let title: String
    let subtitle: String
}
