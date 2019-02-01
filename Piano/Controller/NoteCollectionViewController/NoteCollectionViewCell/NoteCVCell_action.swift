//
//  NoteCVCell_action.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewCell {
    
    static var customMenus: [MenuItem] {
        let items = customSelectors.map {
            return MenuItem(title: $0.1, action: $0.0)
        }
        return items
    }
    
    static var customSelectors: [(Selector, String)] {
        return [(#selector(tapPin(_:)), "📍"),
                (#selector(tapMove(_:)), "🗂"),
                (#selector(tapLock(_:)), "🔒"),
                (#selector(tapExpire(_:)), "💣"),
                (#selector(tapRemove(_:)), "🗑")]
    }
    
    @IBAction func tapPin(_ sender: Any) {
        
    }
    
    @IBAction func tapMove(_ sender: Any) {
        
    }
    
    @IBAction func tapLock(_ sender: Any) {
        
    }
    
    @IBAction func tapExpire(_ sender: Any) {
        
    }
    
    @IBAction func tapRemove(_ sender: Any) {
        
    }

    /// TODO:
    ///     - 액션 시트 만들어서 삭제, 잠금, 이동, 고정, 위젯으로 등록
    ///     - 반복적으로 요청하는 auth request 더 간단하게 할 수 없을지 고민
    @IBAction func tapWriteNowBtn(_ sender: Any) {

    }

}
