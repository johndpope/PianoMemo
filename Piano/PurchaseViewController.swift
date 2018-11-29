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
    @IBOutlet var creditCountLabel: UILabel!
    @IBOutlet var redeemButton: UIButton!
    @IBOutlet var purchaseButton: UIButton!

    private let grayColor = UIColor(red:0.83, green:0.83, blue:0.86, alpha:1.00)

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
        let isRedeemAvailable = Referral.shared.creditCount > product.creditPrice
        if isRedeemAvailable {
            subtitle.isHidden = true
        } else {
            let neededCredit = product.creditPrice - Referral.shared.creditCount
            subtitle.text = "🎹 건반 \(neededCredit)개가 더 필요합니다.\n피아노를 추천하고 건반을 모아보세요."
            let creditCountString = "\(neededCredit)/\(product.creditPrice)"
            let attributed = NSMutableAttributedString(string: "\(Referral.shared.creditCount)/\(product.creditPrice)")
            attributed.addAttribute(.foregroundColor, value: grayColor, range: creditCountString.grayRange)
            creditCountLabel.attributedText = attributed
            redeemButton.isEnabled = false
        }

        redeemButton.setTitle("잠금해제 🎹 x\(product.creditPrice)", for: .normal)
        purchaseButton.setTitle("구매하기 (\(product.price))", for: .normal)
    }

    @IBAction func didTapCancelButton(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func didTapRedeemButton(_ sender: Any) {
        guard let product = product else { return }
        // TODO: 로딩 인디케이터 & 터치 막기
        StoreService.shared.buyProduct(product: product, with: .credit) { success in

            if success {

            }
            // TODO: dismiss & 테이블 갱신
        }
    }

    @IBAction func didTapPurchaseButton(_ sender: Any) {
        guard let product = product else { return }
        // TODO: 로딩 인디케이터 & 터치 막기
        StoreService.shared.buyProduct(product: product, with: .cash) { success in
            if success {
                
            }
            // TODO: dismiss & 테이블 갱신
        }
    }
}

private extension String {
    var grayRange: NSRange {
        if let lower = self.range(of: "/")?.lowerBound {
            let location = self.distance(from: self.startIndex, to: lower)
            let length = self.distance(from: lower, to: self.endIndex)
            return NSRange(location: location, length: length)
        }
        return NSRange()
    }
}

private extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
