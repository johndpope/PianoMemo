//
//  ImageHandlable.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData
import Kuery

protocol ImageHandlable: class {
    var context: NSManagedObjectContext { get }

    func saveImage(image: UIImage?, completion: @escaping (String?) -> Void)
    func removeImage(id: String, completion: @escaping (Bool) -> Void)

    func requestImageIDs(completion:  @escaping ([String]) -> Void)
    func requestImage(id: String, completion: @escaping (UIImage?) -> Void)
}

class ImageHandler: NSObject, ImageHandlable {
    var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

enum ImageHandleError: Error {
    case requesFailed(String)
}

extension ImageHandlable {
    func saveImage(image input: UIImage?, completion: @escaping (String?) -> Void) {
        context.perform { [weak self] in
            guard let self = self, let input = input else { return }
            let image = ImageAttachment(context: self.context)
            image.imageData = input.pngData() as NSData?
            image.localID = UUID().uuidString
            if self.context.saveOrRollback() {
                completion(image.localID)
            } else {
                completion(nil)
            }
        }
    }

    func requestImage(id: String, completion: @escaping (UIImage?) -> Void) {
        context.perform {
            do {
                if let resultData = try Query(ImageAttachment.self)
                    .filter(\ImageAttachment.localID == id)
                    .execute().first?.imageData as Data? {
                    completion(UIImage(data: resultData))
                    return
                }
                completion(nil)
            } catch {
                completion(nil)
            }
        }
    }

    func removeImage(id: String, completion: @escaping (Bool) -> Void) {

    }

    func requestImageIDs(completion:  @escaping ([String]) -> Void) {

    }
}
