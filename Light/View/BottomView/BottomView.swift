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
    
}

class BottomView: View {
    
    @IBOutlet weak var textView: GrowingTextView!
    weak var mainViewController: BottomViewDelegate?
    
    @IBOutlet weak var bottomViewBottomAnchor: LayoutConstraint!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var keyboardHeight: CGFloat?
    


}
