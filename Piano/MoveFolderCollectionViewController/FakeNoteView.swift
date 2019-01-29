//
//  FakeNoteView.swift
//  Piano
//
//  Created by hoemoon on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class FakeNoteView: UIView {
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        return label
    }()
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.numberOfLines = 2
        label.font = UIFont.preferredFont(forTextStyle: .body)
        return label
    }()
    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.font = UIFont.preferredFont(forTextStyle: .caption2)
        return label
    }()

    init(note: Note) {
        super.init(frame: .zero)
        backgroundColor = .white
        titleLabel.text = note.title
        subtitleLabel.text = note.subTitle
        dateLabel.text = DateFormatter.sharedInstance.string(from: note.modifiedAt ?? Date())

        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(dateLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10)
        ])

        layer.cornerRadius = 5
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
