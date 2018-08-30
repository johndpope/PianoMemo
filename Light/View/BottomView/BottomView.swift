//
//  BottomView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

protocol BottomViewDelegate: class {
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView)
    func bottomView(_ bottomView: BottomView, didFinishTyping text: String)
    func bottomView(_ bottomView: BottomView, keyboardWillShow height: CGFloat)
    func bottomView(_ bottomView: BottomView, keyboardWillHide height: CGFloat)
    
}

class BottomView: View {

    /** 키보드에 따른 위치 변화를 위한 컨스트레인트 */
    @IBOutlet weak var bottomConstraint: LayoutConstraint!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var keyboardHeight: CGFloat?
    
    @IBOutlet weak var textView: GrowingTextView!
    weak var mainViewController: BottomViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerKeyboardNotification()
    }
    
    deinit {
        unRegisterKeyboardNotification()
    }

}
