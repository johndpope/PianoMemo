//
//  PDFPreviewVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 25/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension PDFPreviewViewController {
    @IBAction func tapSend(_ sender: BarButtonItem) {
        saveFile { [weak self] url in
            guard let self = self else { return }
            if let url = url {
                let controller = ActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil)
                
                controller.popoverPresentationController?.barButtonItem = sender
                controller.completionWithItemsHandler = {
                    [weak self] type, completed, returnedItems, error in
                    guard let self = self else { return }
                    self.removeFile(url: url)
                }
                self.present(controller, animated: true)
            } else {
                Alert.warning(from: self, title: "Coming soon".loc, message: "😿 Please wait a little longer.".loc)
            }
        }
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        pdfView.scaleFactor = view.bounds.width / 595.2
        pdfView.maxScaleFactor = 1.5
        pdfView.minScaleFactor = view.bounds.width / 700
    }
    
    @IBAction func tapRemove(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
