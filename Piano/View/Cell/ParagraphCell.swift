//
//  TextViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

enum ParagraphTextType {
    case title
    case subTitle
    case accent
    case thin
    
    var font: UIFont {
        switch self {
        case .title:
            return UIFont.preferredFont(forTextStyle: .largeTitle).black
        case .subTitle:
            return UIFont.preferredFont(forTextStyle: .title1).black
        case .accent:
            return UIFont.preferredFont(forTextStyle: .body).black
        case .thin:
            return UIFont.preferredFont(forTextStyle: .largeTitle).thin
        }
    }
    
    var string: String {
        switch self {
        case .title:
            return "title"
        case .subTitle:
            return "subTitle"
        case .accent:
            return "accent"
        case .thin:
            return "thin"
        }
    }
}

struct ParagraphViewModel: ViewModel {
    let str: String
    let viewController: ViewController
    let paraType: ParagraphTextType?
    
    init(str: String, viewController: ViewController, paraType: ParagraphTextType? = nil) {
        self.str = str
        self.viewController = viewController
        self.paraType = paraType
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
            
            if let paraType = paraViewModel.paraType {
                textView.textStorage.addAttributes([.font: paraType.font], range: range)
            } else {
                textView.textStorage.addAttributes([.font: Font.preferredFont(forTextStyle: .body)], range: range)
            }
        }
    }

}


