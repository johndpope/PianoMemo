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

        return "title"
    }

}
