//
//  PianoType.swift
//  PianoNote
//
//  Created by Kevin Kim on 26/03/2018.
//  Copyright © 2018 piano. All rights reserved.
//

import UIKit



extension PianoView {
    
    func setupForPiano(on view: View) {
        view.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        let topAnchor = self.topAnchor.constraint(equalTo: view.topAnchor)
        let leadingAnchor = self.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingAnchor = self.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let bottomAnchor = self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([topAnchor, leadingAnchor, trailingAnchor, bottomAnchor])
    }
    
    func clean() {
        self.removeFromSuperview()
    }
}


