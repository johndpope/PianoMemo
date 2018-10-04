//
//  EmptyStateView.swift
//  Piano
//
//  Created by Kevin Kim on 02/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class EmptyStateView: UIView {

    @IBOutlet weak private var emojiLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    private let emojiList = ["💩","👻","🙅‍♂️","🙅🏻‍♂️","🙅🏼‍♂️","🙅🏽‍♂️","🙅🏾‍♂️","🙅🏿‍♂️","🙅‍♀️","🙅🏻‍♀️","🙅🏼‍♀️","🙅🏽‍♀️","🙅🏾‍♀️","🙅🏿‍♀️","🤷‍♀️","🤷🏻‍♀️","🤷🏼‍♀️","🤷🏽‍♀️","🤷🏾‍♀️","🤷🏿‍♀️","🤷‍♂️","🤷🏻‍♂️","🤷🏼‍♂️","🤷🏽‍♂️","🤷🏾‍♂️","🤷🏿‍♂️","🙈"]
    
    
    private func setup(superView: View, message: String, bottomAnchorConstant: CGFloat? = nil) {
        superView.addSubview(self)
        guard let superView = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: bottomAnchorConstant ?? 0).isActive = true

        let randomIndex = Int(arc4random_uniform(UInt32(emojiList.count)))
        emojiLabel.text = emojiList[randomIndex]
        descriptionLabel.text = message
    }
    
    static func attach(on superView: View, message: String, bottomAnchorConstant: CGFloat? = nil) {
        guard let emptyStateView = superView.createSubviewIfNeeded(EmptyStateView.self) else { return }
        emptyStateView.setup(superView: superView, message: message)
    }
    
    static func detach(on superView: View) {
        guard let emptyStateView = superView.subView(EmptyStateView.self) else { return }
        emptyStateView.removeFromSuperview()
    }
    

}
