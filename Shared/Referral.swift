//
//  Referral.swift
//  Piano
//
//  Created by hoemoon on 15/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import Branch

class Referral: NSObject {
    static let brachUserID = "branchUserIdentifier"
    static let tempBranchID = "tempBranchUserIdentifier"
    static let shareLinkKey = "shareLink"
    private let key = "referralBalance"
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    enum Mode: String {
        case live, test
    }

    static let shared = Referral()

    var cachedLink: String? {
        return UserDefaults.standard.string(forKey: Referral.shareLinkKey)
    }
    private var mode: Mode = .live

    private var balance: Int64 {
        return Int64(keyValueStore.longLong(forKey: key))
    }

    var inviteCount: Int {
        return Int(balance) / 100
    }

    private override init() {
        super.init()
        refreshBalance()
    }

    private func branchKey(type: Mode) -> String {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let keyDict = dict["branch_key"] as? [String: Any],
            let key = keyDict[type.rawValue] as? String {
            return key
        }
        return ""
    }

    private func secretKey(type: Mode) -> String {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let keyDict = dict["branch_secret"] as? [String: Any],
            let key = keyDict[type.rawValue] as? String {
            return key
        }
        return ""
    }

    var identifier: String {
        if let id = NSUbiquitousKeyValueStore.default.string(forKey: Referral.brachUserID) {
            return id
        } else if let id = UserDefaults.standard.string(forKey: Referral.tempBranchID) {
            return id
        } else {
            return ""
        }
    }

    func refreshBalance(completion: ((Bool) -> Void)? = nil) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpCookieAcceptPolicy = .never
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        guard var component = URLComponents(string: "https://api2.branch.io/v1/credits") else { return }
        component.queryItems = [
            URLQueryItem(name: "branch_key", value: branchKey(type: mode)),
            URLQueryItem(name: "identity", value: identifier),
            URLQueryItem(name: "retryNumber", value: UUID().uuidString)
        ]

        guard let url = component.url else { return }
        let task = session.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any],
                    let value = dict["default"] as? Int {
                    let newValue = Int64(value)
                    if newValue != self.balance {
                        self.keyValueStore.set(newValue, forKey: self.key)
                        self.keyValueStore.synchronize()
                    }
                    completion?(true)
                } else {
                    self.keyValueStore.set(Int64(0), forKey: self.key)
                    self.keyValueStore.synchronize()
                    completion?(true)
                }
            } catch {
                print(error)
                completion?(false)
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }

    func redeem(amount: Int,
                logPurchase: (() -> Void)? = nil,
                completion: ((Bool) -> Void)? = nil) {

        guard let url = URL(string: "https://api.branch.io/v1/redeem") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let bodyParameters = [
            "branch_key": branchKey(type: mode),
            "branch_secret": secretKey(type: mode),
            "identity": identifier,
            "bucket": "default",
            "amount": String(amount),
            ]
        let bodyString = bodyParameters.queryParameters
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)

        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            guard let self = self else { return }
            if let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                logPurchase?()
                self.refreshBalance(completion: completion)
            } else {
                completion?(false)
            }
        }
        task.resume()
    }

    func generateLink(completion: @escaping (String) -> Void) {
        let buo = BranchUniversalObject(canonicalIdentifier: UUID().uuidString)
        buo.title = "Piano app download link"
        let lp: BranchLinkProperties = BranchLinkProperties()
        lp.channel = "generated in ios app"
        lp.campaign = "refferral"

        buo.getShortUrl(with: lp) { url, error in
            if let url = url {
                UserDefaults.standard.set(url, forKey: Referral.shareLinkKey)
                completion(url)
            }
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(
                format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            )
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}
