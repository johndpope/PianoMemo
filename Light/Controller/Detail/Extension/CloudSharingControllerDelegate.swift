//
//  CloudSharingControllerDelegate.swift
//  Piano
//
//  Created by hoemoon on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit


extension DetailViewController {
    func cloudSharingController(note: Note, item: UIBarButtonItem) -> UICloudSharingController? {
        guard let archive = note.recordArchive,
            let record = archive.ckRecorded else { return nil }

        let controller = UICloudSharingController {
            [weak self] controller, preparationHandler in
            self?.syncController.requestShare(
                record: record,
                title: nil,
                thumbnailImageData: nil,
                preparationHandler: preparationHandler
            )
        }
        controller.delegate = self
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.popoverPresentationController?.barButtonItem = item
        return controller
    }
}

extension DetailViewController: UICloudSharingControllerDelegate {

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {

        // TODO:
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        return note.title
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
