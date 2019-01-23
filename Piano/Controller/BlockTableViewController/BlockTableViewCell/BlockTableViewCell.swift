//
//  BlockTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class BlockTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: BlockTextView!
    @IBOutlet weak var formButton: UIButton!
    @IBOutlet weak var headerButton: UIButton!
    @IBOutlet weak var blockImageView: UIImageView!
    weak var blockTableVC: BlockTableViewController?
    weak var imageCache: NSCache<NSString, UIImage>?

    var imageID: String!

    var data: String {
        get {

            //TODO: 이부분 계산해서 적용시켜야함
            return ""
        } set {
            setup(string: newValue)
            setupDelegate()
        }
    }

    internal func setupForPianoIfNeeded() {
        guard let vc = blockTableVC else { return }

        if vc.blockTableState == .normal(.piano) {
            textView.isEditable = false
            textView.isSelectable = false

            guard let pianoControl = textView.createSubviewIfNeeded(PianoControl.self),
                let pianoView = vc.navigationController?.view.subView(PianoView.self) else { return }

            pianoControl.attach(on: textView)
            pianoControl.textView = textView
            pianoControl.pianoView = pianoView

        } else {
            textView.isEditable = true
            textView.isSelectable = true
            textView.cleanPiano()

        }

    }

    internal func saveToDataSource() {
        guard let attrText = textView.attributedText,
            let indexPath = blockTableVC?.tableView.indexPath(for: self),
            let vc = blockTableVC else { return }

        let mutableAttrString = NSMutableAttributedString(attributedString: attrText)

        //1. 피아노 효과부터 :: ::를 삽입해준다.
        var highlightRanges: [NSRange] = []
        mutableAttrString.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: mutableAttrString.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color,
                color == Color.highlight else { return }
            highlightRanges.append(range)
        }

        //reverse로 진행된 것이므로, 순차 탐색하면서 :: 넣어주면 된다.
        highlightRanges.forEach {
            mutableAttrString.replaceCharacters(in: NSRange(location: $0.upperBound, length: 0), with: "::")
            mutableAttrString.replaceCharacters(in: NSRange(location: $0.lowerBound, length: 0), with: "::")
        }

        //2. 버튼에 있는 걸 키로 만들어 삽입해준다.
        if let headerStr = headerButton.title(for: .normal) {
            let attrString = NSAttributedString(string: headerStr)
            mutableAttrString.insert(attrString, at: 0)
        } else if let formStr = formButton.title(for: .normal), let bulletValue = PianoBullet(type: .value, text: formStr, selectedRange: NSRange(location: 0, length: 0)) {
            let attrString = NSAttributedString(
                string: bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr)
            mutableAttrString.insert(attrString, at: 0)
        }

        vc.dataSource[indexPath.section][indexPath.row] = mutableAttrString.string
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        blockImageView.image = nil
    }
}
