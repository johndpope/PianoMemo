//
//  PurchaseController.swift
//  Piano
//
//  Created by hoemoon on 13/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import StoreKit

class StoreViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    lazy var fetcher = ReceiptFetcher()

    var products: [SKProduct] {
        return StoreService.shared.products
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetcher.fetch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: .completeTransaction,
            object: nil
        )
    }

    @objc func refresh() {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

extension StoreViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {

        return products.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCell(withIdentifier: StoreCell.id, for: indexPath) as? StoreCell {
            cell.label.text = products[indexPath.row].productIdentifier
            return cell
        }
        return UITableViewCell()
    }
}

extension StoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]

        StoreService.shared.buyProduct(product: product)
    }
}
