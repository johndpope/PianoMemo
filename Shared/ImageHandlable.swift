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
import Result

protocol ImageHandlable: class {
    var context: NSManagedObjectContext { get }

    func saveImage(_ input: UIImage, completion: @escaping (String?) -> Void)
    func saveImages(_ images: [UIImage], completion: @escaping ([String]?) -> Void)
    func removeImage(id: String, completion: @escaping (Bool) -> Void)

    func requestImage(id: String, completion: @escaping (UIImage?) -> Void)

    func requetAllImages(
        completion: @escaping (Result<[ImageAttachment], ImageHandleError>) -> Void)
}

class ImageHandler: NSObject, ImageHandlable {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

enum ImageHandleError: Error {
    case requestFailed(String)
}

extension ImageHandlable {
    func saveImage(_ input: UIImage, completion: @escaping (String?) -> Void) {
        context.performAndWait {
            let image = ImageAttachment.insert(into: context)
            if let thumbnail = input.thumbnail {
                image.imageData = thumbnail.pngData()
            } else {
                image.imageData = input.pngData()
            }
            if context.saveOrRollback() {
                completion(image.localID)
            } else {
                completion(nil)
            }
        }
    }

    func saveImages(_ images: [UIImage], completion: @escaping ([String]?) -> Void) {
        context.performAndWait {
            var ids = [String]()
            images.forEach {
                let image = ImageAttachment.insert(into: self.context)
                ids.append(image.localID ?? "")
                image.imageData = $0.thumbnail?.pngData()
            }
            if context.saveOrRollback() {
                completion(ids)
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
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                guard let image = try Query(ImageAttachment.self)
                    .filter(\ImageAttachment.localID == id)
                    .execute().first else { return }
                image.markForRemoteDeletion()
                completion(self.context.saveOrRollback())
            } catch {
                print(error)
                completion(false)
            }
        }
    }

    func requetAllImages(
        completion: @escaping (Result<[ImageAttachment], ImageHandleError>) -> Void) {

        context.perform {
            do {
                let images = try Query(ImageAttachment.self)
                    .sort(\ImageAttachment.modifiedAt)
                    .reverse()
                    .execute()
                completion(.success(images))
            } catch {
                completion(.failure(.requestFailed(error.localizedDescription)))
            }
        }
    }
}
