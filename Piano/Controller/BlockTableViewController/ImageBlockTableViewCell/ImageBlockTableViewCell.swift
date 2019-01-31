//
//  ImageBlockTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class ImageBlockTableViewCell: UITableViewCell {
    @IBOutlet weak var ibImageView: UIImageView!
    
    var imageValue: PianoImageKey? {
        get {
            return nil
        } set {
            //TODO: fetch해와서 이미지 가져오기
            imageView?.image = #imageLiteral(resourceName: "enableSend")
        }
    }
    


}
