//
//  ImageHandlable.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

protocol ImageHandlable: class {
    var context: NSManagedObjectContext { get }

    func saveImage(_ input: UIImage, completion: @escaping (String?) -> Void)
    func removeImage(id: String, completion: @escaping (Bool) -> Void)
    func requestImage(id: String, completion: @escaping (UIImage?) -> Void)
    func requestAllImages(completion: @escaping ([ImageAttachment]?) -> Void)

}

extension ImageHandlable {
    /// 이미지를 저장합니다.
    func saveImage(_ input: UIImage, completion: @escaping (String?) -> Void) {
        context.performAndWait {
            let image = ImageAttachment.insert(into: context)
            if let thumbnail = input.thumbnail {
                image.imageData = thumbnail.pngData()
            } else {
                image.imageData = input.pngData()
            }
            image.markUploadReserved()
            if context.saveOrRollback() {
                completion(image.localID)
            } else {
                completion(nil)
            }
        }
    }

//    func saveImages(_ images: [UIImage], completion: @escaping ([String]?) -> Void) {
//        context.performAndWait {
//            var ids = [String]()
//            images.forEach {
//                let image = ImageAttachment.insert(into: self.context)
//                ids.append(image.localID ?? "")
//                image.imageData = $0.thumbnail?.pngData()
//            }
//            if context.saveOrRollback() {
//                completion(ids)
//            } else {
//                completion(nil)
//            }
//        }
//    }

    func requestImage(id: String, completion: @escaping (UIImage?) -> Void) {
        context.performAndWait {
            do {
                let request: NSFetchRequest<ImageAttachment> = ImageAttachment.fetchRequest()
                request.predicate = NSPredicate(format: "localID == %@", id)
                request.fetchLimit = 1

                if let data = try context.fetch(request).first?.imageData {
                    completion(UIImage(data: data))
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
    }

    /// 이미지를 제거합니다.
    func removeImage(id: String, completion: @escaping (Bool) -> Void) {
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                let request: NSFetchRequest<ImageAttachment> = ImageAttachment.fetchRequest()
                request.predicate = NSPredicate(format: "localID == %@", id)
                request.fetchLimit = 1
                let fetched = try self.context.fetch(request)
                if let first = fetched.first {
                    first.markForRemoteDeletion()
                    completion(self.context.saveOrRollback())
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }
    }

    /// 모든 이미지를 요청합니다.
    func requestAllImages(completion: @escaping ([ImageAttachment]?) -> Void) {
        context.perform {
            do {
                let request: NSFetchRequest<ImageAttachment> = ImageAttachment.fetchRequest()
                request.predicate = NSPredicate(value: true)
                request.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: true)]
                let fetched = try self.context.fetch(request)

                completion(fetched)
            } catch {
                completion(nil)
            }
        }
    }
}
