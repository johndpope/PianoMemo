//
//  StoreService.swift
//  Block
//
//  Created by JangDoRi on 2018. 8. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import StoreKit

/// Number값을 화폐단위로 변환하는 formatter.
private var localeCurrency: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.formatterBehavior = .behavior10_4
    return formatter
}()

class StoreService: NSObject {
    
    static let share = StoreService()
    
    /// iTunes connect에서 정의한 구독 옵션들.
    var subscriptionOptions: [SubscriptionOption]?
    
    /// 구매내역 존재 유무.
    var hasReceipt: Bool {
        return receipt != nil
    }
    
}

extension StoreService: SKProductsRequestDelegate {
    
    /// iTunes connect에서 정의한 구독 옵션들을 가져온다.
    func loadSubscriptionOptions() {
        let bundleID = Bundle.main.bundleIdentifier! + ".sub."
        let monthly = bundleID + "monthly"
        
        // iTunes connect에서 정의한 각 구독 옵션들의 productIDs.
        let productIDs = Set([monthly])
        
        let productsRequest = SKProductsRequest(productIdentifiers: productIDs)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        subscriptionOptions = response.products.map{SubscriptionOption(product: $0)}
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        // 구독 옵션 가져오기 실패.
    }
    
}

/**
 AppDelegate의 didFinishLaunchingWithOptions에
 SKPaymentQueue.default().add(StoreService.shared)를 선언해서
 app 시작시에 결제정보를 가져오고 검증할 수 있도록 한다.
 */
extension StoreService: SKPaymentTransactionObserver {
    
    /// iTunes connect에 있는 shared Secret.
    private var sharedSecret: String {
        return "passcode" // temp
    }
    
    /** itunes receipt verify URL.
     
     실제 : "https://buy.itunes.apple.com/verifyReceipt"
     테스트 : "https://sandbox.itunes.apple.com/verifyReceipt"
     */
    private var verifyReceiptURL: String {
        return "https://sandbox.itunes.apple.com/verifyReceipt"
    }
    
    /// 가지고 있는 구매내역.
    private var receipt: Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {return nil}
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }
    
    /**
     해당 subscriptionOption의 구매를 진행한다.
     - parameter subscription : 구매하고자 하는 구독 옵션.
     */
    func purchase(subscription: SubscriptionOption) {
        let payment = SKPayment(product: subscription.product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// 기존의 구매내역을 복원한다.
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                handlePurchasingState()
            case .purchased, .restored:
                queue.finishTransaction(transaction)
                handleFinishState()
            case .failed:
                handleFailedState()
            case .deferred:
                handleDeferredState()
            }
        }
    }
    
    private func handlePurchasingState() {
        // Payment transaction 진행중.
    }
    
    private func handleFinishState() {
        guard let receipt = receipt else {return}
        verify(receipt) { success in
            // Payment transaction 성공.
        }
    }
    
    private func handleFailedState() {
        // Payment transaction 실패.
    }
    
    private func handleDeferredState() {
        // Payment transaction 연기.
    }
    
    /**
     구매 또는 복원한 정보를 itunes에 검증한다.
     - parameter receipt : 검증하고자 하는 구매 또는 복원정보.
     - parameter completion : 검증 결과.
     */
    private func verify(_ receipt: Data, completion: @escaping (Bool) -> ()) {
        let body = ["receipt-data": receipt.base64EncodedString(), "password": sharedSecret]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        var request = URLRequest(url: URL(string: verifyReceiptURL)!)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let _ = error {
                completion(false)
            } else if let _ = data {
                // 이 data안에 검증된 결제 정보들이 들어있어 해당 내역을 보면서 이후의 처리를 진행.
                completion(true)
            }
        }
        task.resume()
    }
    
}

/// 구독 옵션.
struct SubscriptionOption {
    
    /// 구독 제품.
    let product: SKProduct
    /// 제품 가격.
    let localePrice: String
    
    init(product: SKProduct) {
        self.product = product
        localeCurrency.locale = product.priceLocale
        localePrice = localeCurrency.string(from: product.price) ?? "\(product.price)"
    }
    
}
