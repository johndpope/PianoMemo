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
    ///
    /// - Parameters:
    ///   - input: UIImage 타입의 이미지를 받습니다.
    ///   - completion: 성공시 이미지 식별자를 받은 completion handler
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

    /// 이미지 식별자를 이용해 이미지를 요청합니다.
    ///
    /// - Parameters:
    ///   - id: 이미지 식별자
    ///   - completion: 성공시 UIImage를 받는 completion handler
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
    ///
    /// - Parameters:
    ///   - id: 이미지 식별자
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
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

    /// 로컬에 저장된 모든 이미지를 요청합니다.
    ///
    /// - Parameter completion: 이미지 목록을 배열로 받는 completion handler
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
