//
//  TagCell.swift
//  Piano
//
//  Created by Kevin Kim on 30/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit


struct TagModel: ViewModel, Collectionable {
    let string: String
    let isEmoji: Bool
    
    init(string: String, isEmoji: Bool) {
        self.string = string
        self.isEmoji = isEmoji
    }
    
    internal func size(view: View) -> CGSize {
        
        var size = isEmoji
        ? NSAttributedString(string: self.string, attributes: [.font : Font.systemFont(ofSize: 26)]).size()
        : NSAttributedString(string: self.string, attributes: [.font : Font.systemFont(ofSize: 15, weight: .semibold)]).size()
        let leadingMargin = 11
        size.width += CGFloat(leadingMargin * 2)
        size.height = 40
        return size
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        
    }
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets.zero
    }
}

class TagModelCell: UICollectionViewCell, ViewModelAcceptable {
    enum SizeState {
        case large, normal
    }

    var viewModel: ViewModel? {
        didSet {
            guard let viewModel = viewModel as? TagModel else { return }
            label.text = viewModel.string
            selectedBackgroundView?.cornerRadius = viewModel.size(view: self).height / 2
            
            label.font = viewModel.isEmoji ? Font.systemFont(ofSize: 26) : Font.systemFont(ofSize: 15, weight: .semibold)
            
        }
    }

    @IBOutlet weak var label: UILabel!

    var topAnchorConstraint: NSLayoutConstraint!
    var centerXConstraint: NSLayoutConstraint!
    var centerYConstraint: NSLayoutConstraint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
        translatesAutoresizingMaskIntoConstraints = false
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        label.translatesAutoresizingMaskIntoConstraints = false

        centerYConstraint = label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        centerXConstraint = label.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        topAnchorConstraint = label.topAnchor.constraint(equalTo: self.topAnchor)

        centerYConstraint.isActive = true
        centerXConstraint.isActive = true
    }

    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        view.cornerRadius = 15
        return view
    }

    override var isSelected: Bool {
        didSet {
            label.textColor = isSelected ? .white : Color(red: 69/255, green: 69/255, blue: 69/255, alpha: 1)
        }
    }

    override func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {

        switch dragState {
        case .dragging:
            setSizeState(.normal)
        case .none:
            setSizeState(.normal)
        default:
            return
        }
    }

    func setSizeState(_ state: SizeState) {
        switch state {
        case .large:
            let newOrigin = CGPoint(
                x: frame.origin.x - 40,
                y: frame.origin.y - 80
            )
            let newSize = CGSize(
                width: frame.size.width + 80,
                height: frame.size.height + 80
            )
            frame = CGRect(origin: newOrigin, size: newSize)
            label.font = Font.systemFont(ofSize: 100)
            topAnchorConstraint.isActive = true
            centerYConstraint.isActive = false
        case .normal:
            if label.font.pointSize == CGFloat(100) {
                let newOrigin = CGPoint(
                    x: frame.origin.x + 40,
                    y: frame.origin.y + 80
                )
                let newSize = CGSize(
                    width: frame.size.width - 80,
                    height: frame.size.height - 80
                )
                frame = CGRect(origin: newOrigin, size: newSize)
                label.font = Font.systemFont(ofSize: 26)
                topAnchorConstraint.isActive = false
                centerYConstraint.isActive = true
            }
        }
    }
}
