//
//  CloudSharingControllerDelegate.swift
//  Piano
//
//  Created by hoemoon on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import MobileCoreServices

extension DetailViewController {
    func cloudSharingController(item: UIBarButtonItem) -> UICloudSharingController? {
        //TODO: COCOA
//        guard let archive = note.recordArchive,
//            let record = archive.ckRecorded else { return nil }
//        var controller: UICloudSharingController!
//
//        if let shareRecordID = record.share?.recordID {
//            controller = UICloudSharingController {
//                [weak self] controller, preparationHandler in
//                self?.syncController.requestManageShare(
//                    shareRecordID: shareRecordID,
//                    preparationHandler: preparationHandler
//                )
//            }
//        } else {
//            controller = UICloudSharingController {
//                [weak self] controller, preparationHandler in
//                self?.syncController.requestShare(
//                    recordToShare: record,
//                    preparationHandler: preparationHandler
//                )
//            }
//            controller.availablePermissions = [.allowPrivate, .allowReadWrite]
//        }
//        controller.delegate = self
//        controller.popoverPresentationController?.barButtonItem = item
//        return controller
        return nil // TODO COCOA: 이 라인 지우기
    }
}

extension DetailViewController: UICloudSharingControllerDelegate {
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {

        // TODO:
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        // 메세지 화면 수준에서 나오면 불림
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        // 메시지로 공유한 후 불림
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        return note.title
    }

    func itemType(for csc: UICloudSharingController) -> String? {
        return kUTTypeContent as String
    }

    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return textView.capture()
    }
}

private extension UIView {
    func capture() -> Data? {
        var image: UIImage?
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = isOpaque
            let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
            image = renderer.image { context in
                drawHierarchy(in: frame, afterScreenUpdates: true)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, UIScreen.main.scale)
            drawHierarchy(in: frame, afterScreenUpdates: true)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image?.jpegData(compressionQuality: 1)
    }
}
