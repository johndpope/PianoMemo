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
    typealias ProductsRequestHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

    private let productIdentifiers: Set<String>
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletion: ProductsRequestHandler?

    private lazy var validator = ReceiptValidator()

    static let shared = StoreService()

    private let storeKey = "PurchaseManager"
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    private(set) var products = [SKProduct]()

    private var cashPurchaseCompletion: ((Bool) -> Void)?
    private var restoreCompletion: ((Bool) -> Void)?

//    func availableProduct() -> Product? {
//        return products.filter { !purchasedIDs.contains($0.id) }
//            .sorted(by: { Int(truncating: $0.price) < Int(truncating: $1.price) }).first
//    }

//    var purchasedIDs: [String] {
//        if let array = keyValueStore.array(forKey: storeKey) as? [String] {
//            return array
//        }
//        return []
//    }

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
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func setup() {
        requestProducts { [unowned self] success, products in
            if success, let products = products {
                self.products = products
            }
        }
    }

    func buyProduct(product: SKProduct, completion: ((Bool) -> Void)? = nil) {
        self.cashPurchaseCompletion = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func buyProduct(formsCount: Int, completion: ((Bool) -> Void)? = nil) {
        guard formsCount - 1 < products.count else { return }
        buyProduct(product: products[formsCount - 1], completion: completion)
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
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

//    private func logPurchase(productID: String) {
//        if let old = keyValueStore.array(forKey: storeKey) as? [String] {
//            var set = Set(old)
//            set.insert(productID)
//            keyValueStore.set(Array(set), forKey: storeKey)
//        } else {
//            let new = [productID]
//            keyValueStore.set(new, forKey: storeKey)
//        }
//        keyValueStore.synchronize()
//    }

}

extension StoreService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsRequestCompletion?(true, response.products)
        clearRequestAndHandler()
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
        productsRequestCompletion?(false, nil)
        clearRequestAndHandler()
    }

    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletion = nil
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
            case .restored:
                restoreTransaction(transaction: transaction)
            case .failed:
                failedTransaction(transaction: transaction)
            default:
                break
            }
        }
    }

    private func completeTransaction(transaction: SKPaymentTransaction) {
//        logPurchase(productID: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        cashPurchaseCompletion?(true)
    }

    private func failedTransaction(transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError,
            error.code != .paymentCancelled {
            cashPurchaseCompletion?(false)
            restoreCompletion?(false)
            print("Transaction error")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restoreTransaction(transaction: SKPaymentTransaction) {
        guard let _ = transaction.original?.payment.productIdentifier else { return }
        restoreCompletion?(true)
        SKPaymentQueue.default().finishTransaction(transaction)
    }


//    private func deliverPurchaseNotificationForIdentifier(identifier: String?) {
//        guard let identifier = identifier else { return }
//        NotificationCenter.default.post(name: .completeTransaction, object: identifier)
//
//        print(identifier)
//    }
}
