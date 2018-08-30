//
//  Color_extension.swift
//  Block
//
//  Created by JangDoRi on 2018. 8. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension Color {
    
    /**
     #RRGGBB로 표현되는 hex값으로 init한다.
     - note: #의 포함 여부는 상관없음.
     - parameter hex6: 6자리 hex값.
     */
    public convenience init(hex6: String) {
        let scan = Scanner(string: hex6.replacingOccurrences(of: "#", with: ""))
        var hex6: UInt32 = 0
        scan.scanHexInt32(&hex6)
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    /**
     #RRGGBBAA로 표현되는 hex값으로 init한다.
     - note: #의 포함 여부는 상관없음.
     - parameter hex8: 6자리 hex + 2자리 alpha값.
     */
    public convenience init(hex8: String) {
        let scan = Scanner(string: hex8.replacingOccurrences(of: "#", with: ""))
        var hex8: UInt32 = 0
        scan.scanHexInt32(&hex8)
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public var hexString: String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"%06x", rgb)
    }
    
}
