//
//  BottomView_TextViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension BottomView: TextViewDelegate {
    

    
    func textViewDidChange(_ textView: TextView) {
        
        mainViewController?.bottomView(self, textViewDidChange: textView)
    }
    

}
