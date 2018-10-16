//
//  CloudSharingControllerDelegate.swift
//  Piano
//
//  Created by hoemoon on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CloudKit
import MobileCoreServices

extension DetailViewController {
    func cloudSharingController(
        note: Note,
        item: UIBarButtonItem,
        completion: @escaping (UICloudSharingController?) -> Void)  {

        guard let record = note.recordArchive?.ckRecorded else { return }

        if let recordID = record.share?.recordID {
            syncController.requestFetchRecords(by: [recordID], isMine: note.isMine) {
                [weak self] recordsByRecordID, operationError in
                if let self = self,
                    let dict = recordsByRecordID,
                    let share = dict[recordID] as? CKShare {

                    let controller = UICloudSharingController(
                        share: share,
                        container: self.syncController.container
                    )
                    controller.delegate = self
                    controller.popoverPresentationController?.barButtonItem = item
                    completion(controller)
                }
            }

        } else {
            let controller = UICloudSharingController {
                [weak self] controller, preparationHandler in
                guard let self = self else { return }
                self.syncController.requestShare(recordToShare: record, preparationHandler: preparationHandler)
            }
            controller.delegate = self
            controller.popoverPresentationController?.barButtonItem = item
            completion(controller)
        }
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
        return note?.title
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
