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
        if let str = DateComponentsFormatter.sharedInstance.string(from: Date(), to: self) {
            let substrs = str.split(separator: " ")
            if substrs.count > 1 {
                do {
                    let firstString = String(substrs.first!)
                    let regex = try NSRegularExpression(pattern: "\\d+", options: .anchorsMatchLines)
                    
                    guard let result = regex.matches(in: firstString, options: .withTransparentBounds, range: NSMakeRange(0, firstString.count)).first else { return str }
                    let range = result.range
                    let nsString = firstString as NSString
                    let numString = nsString.substring(with: range)
                    if let num = Int(numString) {
                        return (firstString as NSString).replacingCharacters(in: range, with: "\(num + 1)")
                    }
                } catch {
                    print("string_extension reminder() 에러: \(error.localizedDescription)")
                }
            }
            
            return str
        }
        return ""
    }
    
    var dDayString: String {
        if let str = DateComponentsFormatter.sharedInstance.string(from: Date(), to: self) {
            let substrs = str.split(separator: " ")
            if substrs.count > 1 {
                do {
                    let firstString = String(substrs.first!)
                    let regex = try NSRegularExpression(pattern: "\\d+", options: .anchorsMatchLines)
                    
                    guard let result = regex.matches(in: firstString, options: .withTransparentBounds, range: NSMakeRange(0, firstString.count)).first else { return str }
                    let range = result.range
                    let nsString = firstString as NSString
                    let numString = nsString.substring(with: range)
                    if let num = Int(numString) {
                        return (firstString as NSString).replacingCharacters(in: range, with: "\(num + 1)")
                    }
                } catch {
                    print("string_extension reminder() 에러: \(error.localizedDescription)")
                }
            }
            
            return str
        }
        return ""
    }
    
}
