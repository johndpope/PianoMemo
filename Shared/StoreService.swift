//
//  StoreService.swift
//  Piano
//
//  Created by hoemoon on 12/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import StoreKit
#if os(macOS)
import IOKit
import OpenSSL
#endif

class StoreService: NSObject {
    enum Method {
        case cash, credit
    }

    typealias ProductsRequestHandler = (_ products: [SKProduct]?) -> Void

    private let productIdentifiers: Set<String>
    private let creditForProductDict: [String: Int]
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletion: ProductsRequestHandler?

    private lazy var validator = ReceiptValidator()

    static let shared = StoreService()

    private let storeKey = "PurchaseManager"
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    private(set) var products = [Product]()

    private var cashPurchaseCompletion: (() -> Void)?

    func availableProduct() -> Product? {
        return products.filter { !purchasedIDs.contains($0.id) }
            .sorted(by: { Int(truncating: $0.price) > Int(truncating: $1.price) }).first
    }

    var purchasedIDs: [String] {
        if let array = keyValueStore.array(forKey: storeKey) as? [String] {
            return array
        }
        return []
    }

    private var validReceipts: [ParsedInAppPurchaseReceipt] {
        switch validator.validate() {
        case .success(let receipt):
            if let receipts = receipt.inAppPurchaseReceipts,
                receipts.count > 0 {

                return receipts
            } else {
                return []
            }
        case .error(let error):
            print(error)
            return []
        }
    }

    private var validPurchasedProductIDs: [String] {
        return validReceipts.compactMap { $0.productIdentifier }
    }

    private override init() {
        let product_ids = Bundle.main.url(forResource: "product_ids", withExtension: "plist")!
        let array = NSArray(contentsOf: product_ids) as! [String]
        self.productIdentifiers = Set(array)

        let creditForProduct = Bundle.main.url(forResource: "credit_product", withExtension: "plist")!
        self.creditForProductDict = NSDictionary(contentsOf: creditForProduct) as! [String: Int]
        
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func setup() {
        requestProducts { [unowned self] products in
            guard let products = products else { return }
            for skProduct in products {
                if let credit = self.creditForProductDict[skProduct.productIdentifier] {
                    self.products.append(Product(skProduct: skProduct, creditPrice: credit))
                }
            }
        }
    }

    func logPurchase(productID: String) {
        if let old = keyValueStore.array(forKey: storeKey) as? [String] {
            var set = Set(old)
            set.insert(productID)
            keyValueStore.set(Array(set), forKey: storeKey)
        } else {
            let new = [productID]
            keyValueStore.set(new, forKey: storeKey)
        }
        keyValueStore.synchronize()
    }


    func refresh() {

    }
}

extension StoreService {
    func requestProducts(completion: @escaping ProductsRequestHandler) {
        productsRequest?.cancel()
        self.productsRequestCompletion = completion

        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    func buyProduct(product: Product, with method: Method, completion: (() -> Void)? = nil) {
        switch method {
        case .cash:
            self.cashPurchaseCompletion = completion
            let payment = SKPayment(product: product.skProduct)
            SKPaymentQueue.default().add(payment)
        case .credit:
            Referral.shared.redeem(amount: product.creditPrice, completion: completion)
        }
    }

}

extension StoreService: SKProductsRequestDelegate {
    func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse) {

        productsRequestCompletion?(response.products)
        productsRequestCompletion = nil
        productsRequest = nil
    }

}

extension StoreService: SKPaymentTransactionObserver {
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]) {

        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                completeTransaction(transaction: transaction)
            case .failed:
                failedTransaction(transaction: transaction)
            default:
                print()
            }
        }
    }

    private func completeTransaction(transaction: SKPaymentTransaction) {
//        deliverPurchaseNotificationForIdentifier(identifier: transaction.payment.productIdentifier)
        logPurchase(productID: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        cashPurchaseCompletion?()
    }

    private func failedTransaction(transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError,
            error.code != .paymentCancelled {
            print("Transaction error")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }

//    private func deliverPurchaseNotificationForIdentifier(identifier: String?) {
//        guard let identifier = identifier else { return }
//        NotificationCenter.default.post(name: .completeTransaction, object: identifier)
//
//        print(identifier)
//    }
}
