//
//  RecommandOperation.swift
//  Piano
//
//  Created by Kevin Kim on 23/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import EventKit
import Contacts

//텍스트 + selectedRange를 받으면 나머지 작업을 다 수행함
class RecommandOperation: Operation {
    let text: String
    let selectedRange: NSRange
    let completion: (Recommandable?) -> Void
    
    init(text: String, selectedRange: NSRange, completion: @escaping (Recommandable?) -> Void) {
        self.text = text
        self.selectedRange = selectedRange
        self.completion = completion
        super.init()
    }
    
    override func main() {
        if isCancelled { return }
        let paraRange = (text as NSString).paragraphRange(for: selectedRange)
        let paraStr = (text as NSString).substring(with: paraRange)
        if isCancelled { return }
        completion(paraStr.recommandData)
    }
}

