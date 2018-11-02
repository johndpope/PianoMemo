//
//  EmojiParser.swift
//  Piano
//
//  Created by hoemoon on 01/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct Emoji {
    let string: String
    let category: String
    let isRecommended: Bool
    let description: String

    init(string: String,
         category: String = "",
         isRecommended: Bool = false,
         description: String = "") {

        self.string = string
        self.category = category
        self.isRecommended = isRecommended
        self.description = description
    }
}

extension Emoji: Collectionable {
    func size(view: View) -> CGSize {
        let viewWidth = view.bounds.width
        var n = 1
        var usedWidth: CGFloat = 0
        while true {
            let width = CGFloat(50 * n)
            if width > viewWidth { break }
            usedWidth = width
            n += 1
        }
        let plusFloat = (viewWidth - usedWidth) / CGFloat(n)
        let plusInt = Int(plusFloat)
        return CGSize(width: 50 + plusInt, height: 50 + plusInt)
    }
}

class EmojiParser {
    private let string: String
    private var rows: [String] {
        return string.components(separatedBy: "\n")
    }

    var emojis = [Emoji]()
    var categories = Set<String>()

    init?(filename: String) {
        let components = filename.components(separatedBy: ".")
        guard components.count == 2,
            let path = Bundle.main.path(
                forResource: components[0],
                ofType: components[1]) else { return nil }

        if let string = try? String(contentsOfFile: path, encoding: .utf8) {
            self.string = string
        } else {
            return nil
        }
    }

    @discardableResult
    func setup() -> Bool? {
        let filtered = rows.filter { $0.count > 0 }
        for row in filtered {
            let components = row.components(separatedBy: ",")
            guard components.count == 4 else { return nil }
            let isRecommended = components[2] == "1" ? true : false

            let emoji = Emoji(
                string: components[0],
                category: components[1],
                isRecommended: isRecommended,
                description: components[3]
            )
            categories.insert(components[1])
            emojis.append(emoji)
        }
        return true
    }
}
