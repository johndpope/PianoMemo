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

/// 앱 내 구매 기능에 대한 인터페이스를 제공합니다.
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
    var didPurchaseListShortcutUnlocker: Bool {
        return validPurchasedProductIDs.contains(listUnlockerID)
    }

    private var cashPurchaseCompletion: ((SKPaymentTransactionState, Error?) -> Void)?
    private var restoreCompletion: ((SKPaymentTransactionState, Error?) -> Void)?

    /// 디스크에 저장된 제품 목록을 객체 형태로 바꿔서 메모리에 올린다.
    private override init() {
        let product_ids = Bundle.main.url(forResource: "product_ids", withExtension: "plist")!
        if let array = NSArray(contentsOf: product_ids) as? [String] {
            self.productIdentifiers = Set(array)
        } else {
            self.productIdentifiers = Set<String>()
        }
        super.init()
        SKPaymentQueue.default().add(self)
    }

    /// 외부에서 호출되는 메서드
    /// 제품 목록을 준비시킨다.
    func setup() {
        requestProducts { [unowned self] success, products in
            if success, let products = products {
                self.products = products
            }
        }
    }

    /// 제품 목록에서 unlocker를 선택해서 구매를 요청하는 메서드
    /// 실제 구매 요청은 buyProduct(product:completion:)에서 하게 된다.
    ///
    /// - Parameter completion: 거래 결과와 발생한 에러 객체를 받는 completion handler
    func buyListShortcutUnlocker(completion: ((SKPaymentTransactionState, Error?) -> Void)? = nil) {
        let unlocker = products.filter({ $0.productIdentifier == listUnlockerID }).first
        switch unlocker {
        case .some(let unwrapped):
            buyProduct(product: unwrapped, completion: completion)
        case .none:
            completion?(.failed, nil)
        }
    }

    /// 구매 복원을 요청하는 메서드
    ///
    /// - Parameter completion: 거래 결과와 발생한 에러 객체를 받는 completion handler
    func restorePurchases(completion: ((SKPaymentTransactionState, Error?) -> Void)? = nil) {
        SKPaymentQueue.default().restoreCompletedTransactions()
        restoreCompletion = completion
    }

    /// 구매 가능을 확인하는 메서드
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

}

extension StoreService {
    /// 영수증을 확인해서 유효한 제품 목록을 반환합니다.
    private var validPurchasedProductIDs: [String] {
        return validReceipts.compactMap { $0.productIdentifier }
            .filter { productIDs.contains($0) }
    }

    ///  ReceiptValidator 객체를 이용해 로컬에 있는 유효한 영수증들을 반환합니다.
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

    /// 실제로 구매를 요청하는 메서드
    ///
    /// - Parameters:
    ///   - product: 제품 객체
    ///   - completion: 거래 결과와 발생한 에러 객체를 받는 completion handler
    private func buyProduct(product: SKProduct, completion: ((SKPaymentTransactionState, Error?) -> Void)? = nil) {
        cashPurchaseCompletion = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    /// 제품 목록을 요청하는 메서드
    ///
    /// - Parameter completion: 성공 여부와 제품 목록을 받는 completion handler
    private func requestProducts(completion: @escaping ProductsRequestHandler) {
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
                purchased(transaction: transaction)
            case .restored:
                restored(transaction: transaction)
            case .failed:
                failed(transaction: transaction)
            case .deferred:
                deferred(transaction: transaction)
            default:
                break
            }
        }
    }

    /// 구매 성공시 호출되는 메서드
    private func purchased(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        cashPurchaseCompletion?(transaction.transactionState, nil)
    }

    /// 구매 실패시 호출되는 메서드
    private func failed(transaction: SKPaymentTransaction) {
        cashPurchaseCompletion?(transaction.transactionState, transaction.error)
        restoreCompletion?(transaction.transactionState, transaction.error)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    /// 구매 복원시 호출되는 메서드
    private func restored(transaction: SKPaymentTransaction) {
        guard transaction.original?.payment.productIdentifier != nil else { return }
        restoreCompletion?(transaction.transactionState, nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    /// 구매가 지연될 경우 호출되는 메서드
    /// 부모의 승인이 필요한 구매의 경우 구매가 지연될 수 있습니다.
    private func deferred(transaction: SKPaymentTransaction) {
        cashPurchaseCompletion?(transaction.transactionState, nil)
    }
}
