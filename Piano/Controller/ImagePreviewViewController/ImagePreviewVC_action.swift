//
//  ImagePreviewVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 25/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ImagePreviewViewController {
    @IBAction func tapRemove(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapAction(_ sender: BarButtonItem) {
        guard let data = jpegData else { return }
        Analytics.logEvent(shareNote: note, format: "image")
        let controller = ActivityViewController(activityItems: [data], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = sender
        present(controller, animated: true)
    }
}
