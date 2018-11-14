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
    typealias ProductsRequestHandler = (_ products: [SKProduct]?) -> Void

    private let productIdentifiers: Set<String>
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletion: ProductsRequestHandler?

    private lazy var validator = ReceiptValidator()

    static let shared = StoreService()

    private(set) var products = [Product]()

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
        let url = Bundle.main.url(forResource: "product_ids", withExtension: "plist")!
        let array = NSArray(contentsOf: url) as! [String]
        self.productIdentifiers = Set(array)
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func setup() {
        requestProducts { [unowned self] products in
            guard let products = products else { return }
            var tempProducts = [Product]()

            for skProduct in products {
                if self.validPurchasedProductIDs.contains(skProduct.productIdentifier) {
                    var product = Product(skProduct: skProduct)
                    product.isPurchased = true
                    tempProducts.append(product)
                }
            }
        }
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

    func buyProduct(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
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
        deliverPurchaseNotificationForIdentifier(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func failedTransaction(transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError,
            error.code != .paymentCancelled {
            print("Transaction error")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func deliverPurchaseNotificationForIdentifier(identifier: String?) {
        guard let identifier = identifier else { return }
        NotificationCenter.default.post(name: .completeTransaction, object: identifier)
    }
}
