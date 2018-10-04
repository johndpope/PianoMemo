//
//  Date_extension.swift
//  Piano
//
//  Created by Kevin Kim on 21/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//
import Foundation
import UIKit

extension Date {
    
    func years(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.year], from: sinceDate, to: self).year
    }
    
    func months(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.month], from: sinceDate, to: self).month
    }
    
    func days(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: sinceDate, to: self).day
    }
    
    func hours(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.hour], from: sinceDate, to: self).hour
    }
    
    func minutes(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.minute], from: sinceDate, to: self).minute
    }
    
    func seconds(sinceDate: Date) -> Int? {
        return Calendar.current.dateComponents([.second], from: sinceDate, to: self).second
    }
    
    var dDay: String {
        if let str = DateComponentsFormatter.sharedInstance.string(from: Date(), to: self),
            var firstStr = str.split(separator: " ").first {
            
            //d가 있다면 일 후로 표시
            //h가 있다면 시간 후로 표시
            //TODO: 코드가 상당히 위험함. 보완해야함
            if firstStr.contains("d") {
                firstStr.removeCharacters(strings: ["d"])
                let dayInteger = Int(firstStr) ?? 0
                if dayInteger > 0 {
                    return "\(dayInteger + 1)일 후"
                } else {
                    return "\(dayInteger + 1)일 전"
                }
                
            } else if firstStr.contains("h") {
                firstStr.removeCharacters(strings: ["h"])
                let hourInteger = Int(firstStr) ?? 0
                if hourInteger > 0 {
                    return "\(hourInteger)시간 후"
                } else {
                    return "\(hourInteger)시간 전"
                }
            } else {
                return ""
            }
        }
        return ""
    }
    
}
