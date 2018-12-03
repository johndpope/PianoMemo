//
//  EmptyInputView.swift
//  Piano
//
//  Created by Kevin Kim on 16/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class EmptyInputView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addKeyboardButton: UIButton!
    
    var completionHandler: (() -> Void)?
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        titleLabel.text = "이모티콘 키보드를 찾을 수 없어요 😥".loc
        descriptionLabel.text = "⚙️ 설정 > 일반 > 키보드 > 새로운 키보드 추가 > 이모티콘 키보드를 찾아 추가해주세요".loc
        addKeyboardButton.setTitle("이모티콘 키보드 추가".loc, for: .normal)
    }
    

    @IBAction func moveToSetting(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { [weak self] (success) in
                self?.completionHandler?()
            })
        }
        
        
    }
}
