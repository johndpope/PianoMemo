//
//  ImageHandlable.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

protocol ImageHandlable {
    var backgroundContext: NSManagedObjectContext! { get }

    func saveImage(image: UIImage, completion: @escaping (String) -> Void)
    func removeImage(with id: String, completion: @escaping (Bool) -> Void)

    func requestImageIDs(completion:  @escaping ([String]) -> Void)
    func requestImage(with id: String, completion: @escaping (UIImage) -> Void)
}
