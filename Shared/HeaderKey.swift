//
//  HeaderKey.swift
//  Piano
//
//  Created by Kevin Kim on 29/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

public enum PianoHeaderType {
    case title1
    case title2
    case title3
}

public struct HeaderKey {
    private let regexs: [(type: PianoHeaderType, regex: String)] = [
        (.title1, "^\\s*(#)(?= )"),
        (.title2, "^\\s*(##)(?= )"),
        (.title3, "^\\s*(###)(?= )")
    ]
    
    public var type: PianoHeaderType
    public var whitespaces: (string: String, range: NSRange)
    public var string: String
    public var range: NSRange
    public let paraRange: NSRange
    public let paraText: String

    public var font: Font {
        switch type {
        case .title1:
            return Font.preferredFont(forTextStyle: .title1).black
        case .title2:
            return Font.preferredFont(forTextStyle: .title2).black
        case .title3:
            return Font.preferredFont(forTextStyle: .title3).black
        }
    }

    public var fontForPDF: Font {
        switch type {
        case .title1:
            return Font.preferredFont(forTextStyle: .title1).withSize(24).black
        case .title2:
            return Font.preferredFont(forTextStyle: .title2).withSize(20).black
        case .title3:
            return Font.preferredFont(forTextStyle: .title3).withSize(16).black
        }
    }

    public var baselineIndex: Int {
        return range.upperBound + 1
    }

    public init?(text: String, selectedRange: NSRange) {
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)

        for (type, regex) in regexs {
            if let (string, range) = text.detect(searchRange: paraRange, regex: regex) {
                self.type = type
                self.paraText = text
                self.string = string
                self.range = range
                let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
                let wsString = nsText.substring(with: wsRange)
                self.whitespaces = (wsString, wsRange)
                self.paraRange = paraRange
                return
            }
        }

        return nil
    }

    public var rangeToRemove: NSRange {
        return NSRange(location: whitespaces.range.upperBound, length: baselineIndex - whitespaces.range.upperBound)
    }

    func paraStyleForPDF() -> ParagraphStyle {
        let mutableParaStyle = MutableParagraphStyle()

        mutableParaStyle.lineSpacing = 0
        let paraSpacing: CGFloat
        switch type {
        case .title1:
            paraSpacing = 10
        case .title2:
            paraSpacing = 8
        case .title3:
            paraSpacing = 6
        }
        mutableParaStyle.paragraphSpacing = paraSpacing
        return mutableParaStyle
    }

}
