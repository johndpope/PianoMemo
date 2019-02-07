//
//  UIImage_extension.swift
//  Piano
//
//  Created by Kevin Kim on 02/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit


extension UIImage {
    var thumbnail: UIImage? {
        guard let pngData = self.pngData() else { return nil }
        let imageData = NSData(data: pngData)
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024] as CFDictionary
        if let source = CGImageSourceCreateWithData(imageData, nil),
            let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) {
            return UIImage(cgImage: imageReference)
        }
        return nil
    }
}
