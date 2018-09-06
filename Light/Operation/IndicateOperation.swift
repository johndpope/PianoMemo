//
//  IndicateOperation.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class IndicateOperation: Operation {
    let rawText: String
    let completion: ([Indicator]) -> Void

    init(rawText: String,
         completion: @escaping ([Indicator]) -> Void) {

        self.rawText = rawText
        self.completion = completion
        super.init()
    }

    override func main() {
        if isCancelled { return }
        var indicators = Array<Indicator>()

        let paraArray = rawText.components(separatedBy: .newlines)
        for paraString in paraArray {
            if isCancelled { return }
            if let reminder = paraString.reminder() {
                indicators.append(Indicator(type: .reminder, reminder: reminder))
            } else if let contact = paraString.contact() {
                indicators.append(Indicator(type: .contact, contact: contact))
            } else if let event = paraString.event() {
                indicators.append(Indicator(type: .event, event: event))
            }
        }
        if isCancelled { return }
        completion(Array(indicators))
    }
}
