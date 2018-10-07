//
//  TextViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

enum FontType {
    case largeTitle
    case title1
    case title2
    case body
    
    var font: UIFont {
        switch self {
        case .largeTitle:
            return UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title1:
            return UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2)
        case .body:
            return UIFont.preferredFont(forTextStyle: .body)
        }
    }
    
    var string: String {
        switch self {
        case .largeTitle:
            return "대제목"
        case .title1:
            return "중제목"
        case .title2:
            return "소제목"
        case .body:
            return "본문"
        }
    }
}

enum AttributeType: Equatable {
    case black(Font)
    case medium(Font)
    case thin(Font)
    case body(Font)
    
    var attr: [NSAttributedString.Key : Any] {
        switch self {
        case .black(let x):
            return [.font : x.black]
        case .medium(let x):
            return [.font : x.medium]
        case .thin(let x):
            return [.font : x.thin]
        case .body(let x):
            return [.font : x.body]
        }
    }
    
    var string: String {
        switch self {
        case .black:
            return "black"
        case .medium:
            return "medium"
        case .thin:
            return "thin"
        case .body:
            return "body"
        }
    }
}

struct ParagraphViewModel: ViewModel {
    let str: String
    let viewController: ViewController
    let fontType: FontType?
    let attrType: AttributeType?
    
    init(str: String, viewController: ViewController, fontType: FontType? = nil, attrType: AttributeType? = nil) {
        self.str = str
        self.viewController = viewController
        self.fontType = fontType
        self.attrType = attrType
    }
    
}


class ParagraphCell: UITableViewCell, ViewModelAcceptable {
    
    @IBOutlet weak var textView: BlockTextView!
    var viewModel: ViewModel? {
        didSet {
            guard let paraViewModel = viewModel as? ParagraphViewModel else { return }
            let str = paraViewModel.str
            textView.attributedText = str.createFormatAttrString(fromPasteboard: false)
            
            let range = NSMakeRange(0, textView.attributedText.length)
            if let fontType = paraViewModel.fontType {
                textView.textStorage.addAttributes([.font: fontType.font], range: range)
            }
            
            if let attrType = paraViewModel.attrType {
                textView.textStorage.addAttributes(attrType.attr, range: range)
            }
            
        }
    }

}


