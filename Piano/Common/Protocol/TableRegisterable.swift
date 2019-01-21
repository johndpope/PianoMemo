//
//  TableRegisterable.swift
//  Piano
//
//  Created by Kevin Kim on 11/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

protocol TableRegisterable: class {
    var tableView: TableView! { get set }
}

extension TableRegisterable {
    func registerCell<T: View>(_ type: T.Type) {
        self.tableView.register(Nib(nibName: type.reuseIdentifier, bundle: nil), forCellReuseIdentifier: type.reuseIdentifier)
    }

    func registerHeaderView<T: View>(_ type: T.Type) {
        tableView.register(Nib(nibName: type.reuseIdentifier, bundle: nil), forHeaderFooterViewReuseIdentifier: type.reuseIdentifier)
    }

}
