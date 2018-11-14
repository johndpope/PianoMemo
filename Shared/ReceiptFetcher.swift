//
//  ReceiptFetcher.swift
//  Piano
//
//  Created by hoemoon on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import StoreKit

class ReceiptFetcher: NSObject {
    lazy var request: SKReceiptRefreshRequest = {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        return request
    }()

    func fetch() {
        let receiptUrl = Bundle.main.appStoreReceiptURL

        do {
            if let receiptFound = try receiptUrl?.checkResourceIsReachable() {
                if (receiptFound == false) {
                    request.start()
                }
            }
        } catch {
            print("Could not check for receipt presence for some reason... \(error.localizedDescription)")
        }
    }
}

extension ReceiptFetcher: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        print("finished")
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("failed")
    }
}
