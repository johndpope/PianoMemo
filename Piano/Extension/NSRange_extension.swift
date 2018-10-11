//
//  NSRange_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 8. 9..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension NSRange {
    internal func move(offset: Int) -> NSRange {
        return NSMakeRange(self.location + offset, self.length)
    }
}
