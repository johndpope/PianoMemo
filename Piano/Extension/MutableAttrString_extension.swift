//
//  MutableAttrString_extension.swift
//  Piano
//
//  Created by Kevin Kim on 19/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    
    internal func addLinkAttr(searchRange: NSRange){
        let types: NSTextCheckingResult.CheckingType = [.link]
        do {
            let detector = try NSDataDetector(types: types.rawValue)
            let matches = detector.matches(in: self.string, options: .reportCompletion, range: searchRange)
            
            for match in matches {
                if let url = match.url {
                    addAttributes([.link : url], range: match.range)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
