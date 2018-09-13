//
//  GTLRGmail_MessagePart_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST

extension GTLRGmail_MessagePart {
    internal var from: String {
        if let from = self.headers?.first(where: {$0.name == "From"})?.value, !from.isEmpty {
            let replacedFrom = from.replacingOccurrences(of: "\"", with: "")
            return replacedFrom.sub(...replacedFrom.index(of: " "))
        }
        return ""
    }
    
    internal var html: String? {
        guard let mimeType = self.mimeType else {return ""}
        if mimeType.contains("multipart") {
            guard let parts = self.parts else {return ""}
            
            for part in parts {
                guard let mimeType = part.mimeType, mimeType.contains("html") else {continue}
                guard let base64url = part.body?.data else {continue}
                guard let base64 = Data(base64Encoded: self.base64(from: base64url)) else {continue}
                return String(data: base64, encoding: .utf8)
            }
        } else {
            guard let base64url = self.body?.data else {return ""}
            guard let base64 = Data(base64Encoded: self.base64(from: base64url)) else {return ""}
            return String(data: base64, encoding: .utf8)
        }
        return ""
    }
    
    
    
    private func base64(from base64url: String) -> String {
        var base64 = base64url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {base64.append(String(repeating: "=", count: 4 - base64.count % 4))}
        return base64
    }
}
