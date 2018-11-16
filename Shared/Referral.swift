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
    enum Mode: String {
        case live, test
    }

    static let shared = Referral()
    private var mode: Mode = .test

    var balance: Int = 0 {
        willSet {
            let dict = ["balance": newValue]
            NotificationCenter.default.post(name: .balanceChange, object: nil, userInfo: dict)
        }
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
        if let id = UserDefaults.getUserIdentity()?.userRecordID?.recordName {
            return id
        }
        return ""
    }

//    func login() {
//        if let identity = UserDefaults.getUserIdentity(),
//            let recordName = identity.userRecordID?.recordName {
//            Branch.getInstance().setIdentity(recordName)
//        }

//        Branch.getInstance()?.setIdentity("99999999999999")
//    }

//    func logout() {
//        Branch.getInstance().logout()
//    }

    func refreshBalance() {
        guard var component = URLComponents(string: "https://api.branch.io/v1/credits") else { return }
        component.queryItems = [
            URLQueryItem(name: "branch_key", value: branchKey(type: mode)),
            URLQueryItem(name: "identity", value: identifier)
        ]
        guard let url = component.url else { return }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String: Any],
                let value = dict["default"] as? Int {

                self.balance = value
            }
        }
        task.resume()
    }

    func redeem(amount: Int) {
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
                self.refreshBalance()
            }
        }
        task.resume()
    }

    func generateLink(completion: @escaping (String) -> Void) {
        let buo = BranchUniversalObject.init(canonicalIdentifier: UUID().uuidString)
        buo.title = "Refferral"
        let lp: BranchLinkProperties = BranchLinkProperties()
        lp.channel = "channel"
        lp.campaign = "refferral"

        buo.getShortUrl(with: lp) { url, error in
            if let url = url {
                print(url)
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
