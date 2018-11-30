//
//  PurchaseViewController.swift
//  Piano
//
//  Created by hoemoon on 29/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PurchaseViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var redeemButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var cancelButton: UIButton!

    private let grayColor = UIColor(red:0.83, green:0.83, blue:0.86, alpha:1.00)
    var didSuccessPurchase: Bool? = nil

    var product: Product?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(with: product)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.roundCorners([.topLeft, .topRight], radius: 10)
    }

    private func setup(with product: Product?) {
        guard let product = product else { return }
        titleLabel.text = product.title
        subtitle.text = "이모지 체크리스트를 추가하여\n다양한 이모지로 메모를 꾸며보세요 "
        let isRedeemAvailable = Referral.shared.creditCount > product.creditPrice
        redeemButton.isEnabled = isRedeemAvailable
        redeemButton.setTitle("건반으로 구매 🎹 x\(product.creditPrice)", for: .normal)
        redeemButton.setTitle("건반이 부족해요 🎹 x\(product.creditPrice)", for: .disabled)
        if isRedeemAvailable {
            redeemButton.backgroundColor = UIColor.black
        } else {
            redeemButton.backgroundColor = UIColor(red:0.80, green:0.81, blue:0.86, alpha:1.00)
        }
    }

    @IBAction func didTapCancelButton(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func didTapRedeemButton(_ sender: Any) {
        guard let product = product else { return }
        activityIndicator.startAnimating()
        cancelButton.isEnabled = false

        StoreService.shared.buyProduct(product: product, with: .credit) {
            [weak self] success in
            guard let self = self else { return }
            if success {
                self.didSuccessPurchase = true
            } else {
                self.didSuccessPurchase = false
            }
            self.cancelButton.isEnabled = true
            self.activityIndicator.stopAnimating()
            self.dismiss(animated: true, completion: nil)
        }
    }

//    @IBAction func didTapPurchaseButton(_ sender: Any) {
//        guard let product = product else { return }
//        // TODO: 로딩 인디케이터 & 터치 막기
//        StoreService.shared.buyProduct(product: product, with: .cash) { success in
//            if success {
//
//            }
//            // TODO: dismiss & 테이블 갱신
//        }
//    }
}

private extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
