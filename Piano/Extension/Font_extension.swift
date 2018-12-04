//
//  Font_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 16..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension UIFont {
    var black: UIFont { return withWeight(.black) }
    var medium: UIFont { return withWeight(.medium) }
    var thin: UIFont { return withWeight(.thin) }
    var body: UIFont { return withWeight(.regular) }
    
    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
    

}
