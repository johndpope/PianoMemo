//
//  NSRange.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 19..
//  Copyright © 2018년 piano. All rights reserved.
//

extension NSRange {
    
    func difference(to range: NSRange) -> (NSRange?, NSRange?) {
        if let intersection = self.intersection(range) {
            
            if intersection.location == self.location {
                return intersection.length == self.length ? (nil,nil): (nil,NSMakeRange(self.location + intersection.length, self.length - intersection.length))
            } else {
                let firstChunk = NSMakeRange(self.location, intersection.location - self.location)
                let secondChunk = NSMakeRange(intersection.upperBound, self.upperBound - intersection.upperBound)
                
                if secondChunk.length == 0 {
                    return (firstChunk, nil)
                } else {
                    return (firstChunk,secondChunk)
                }
            }
        }
        return (self, nil)
    }
    
    func shift(by offset: Int) -> NSRange {
        return NSMakeRange(self.location + offset, self.length)
    }
}
