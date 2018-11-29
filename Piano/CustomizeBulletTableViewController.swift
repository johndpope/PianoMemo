//
//  CustomizeBulletTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class CustomizeBulletViewController: UIViewController {
    lazy var overrayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    @IBOutlet var tableView: UITableView!
    @IBOutlet var accessoryToolbar: UIToolbar!

    lazy var listSlotProduct = Product(title: "리스트 슬롯 추가", creditPrice: 5, moneyPrice: 0.99)

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapDone(_ sender: Any) {
        view.endEditing(true)
    }
    
    // MARK: - Table view data source


    func showPurchase() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let controller = storyboard.instantiateViewController(withIdentifier: PurchaseViewController.identifier) as? PurchaseViewController {

            controller.product = listSlotProduct
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = self
            addOverray()
            present(controller, animated: true)
        }
    }

    func addOverray() {
        navigationController?.view.addSubview(overrayView)

        NSLayoutConstraint.activate([
            overrayView.heightAnchor.constraint(equalTo: view.heightAnchor),
            overrayView.widthAnchor.constraint(equalTo: view.widthAnchor),
            overrayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overrayView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }
}

extension CustomizeBulletViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomizeBulletCell.reuseIdentifier, for: indexPath) as! CustomizeBulletCell

        let userDefineForm = PianoBullet.userDefineForms.count > indexPath.row ? PianoBullet.userDefineForms[indexPath.row] : nil

        cell.userDefineForm = userDefineForm
        cell.vc = self
        cell.textField.inputAccessoryView = accessoryToolbar
        cell.emojiTextField.inputAccessoryView = accessoryToolbar

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "FooterCell")?.contentView
        return view
    }

}

extension CustomizeBulletViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfSizePresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        overrayView.removeFromSuperview()
        return nil
    }
}

class HalfSizePresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return CGRect.zero }
        return CGRect(
            x: 0,
            y: container.bounds.height / 2,
            width: container.bounds.width,
            height: container.bounds.height / 2
        )
    }
}
