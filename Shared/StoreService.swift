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
    private let listUnlockerID = "com.pianonoteapp.unlock.listshortcut"

    static let shared = StoreService()

    private(set) var products = [SKProduct]()
    private var productIDs: [String] {
        return products.map { $0.productIdentifier }
    }
    private var validPurchasedProductIDs: [String] {
        return validReceipts.compactMap { $0.productIdentifier }
            .filter { productIDs.contains($0) }
    }
    var didPurchaseListShortcutUnlocker: Bool {
        return validPurchasedProductIDs.contains(listUnlockerID)
    }

    private var cashPurchaseCompletion: ((Bool, SKError?) -> Void)?
    private var restoreCompletion: ((Bool, SKError?) -> Void)?

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

    func buyProduct(product: SKProduct, completion: ((Bool, SKError?) -> Void)? = nil) {
        cashPurchaseCompletion = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func buyListShortcutUnlocker(completion: ((Bool, SKError?) -> Void)? = nil) {
        if let unlocker = products.filter({ $0.productIdentifier == listUnlockerID }).first {
            buyProduct(product: unlocker, completion: completion)
        }
    }

    func restorePurchases(completion: ((Bool, SKError?) -> Void)? = nil) {
        SKPaymentQueue.default().restoreCompletedTransactions()
        restoreCompletion = completion
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
        SKPaymentQueue.default().finishTransaction(transaction)
        cashPurchaseCompletion?(true, nil)
    }

    private func failedTransaction(transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            switch error.code {
            case .paymentCancelled:
                cashPurchaseCompletion?(false, nil)
                restoreCompletion?(false, nil)
            default:
                cashPurchaseCompletion?(false, error)
                restoreCompletion?(false, error)
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restoreTransaction(transaction: SKPaymentTransaction) {
        guard let _ = transaction.original?.payment.productIdentifier else { return }
        restoreCompletion?(true, nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
