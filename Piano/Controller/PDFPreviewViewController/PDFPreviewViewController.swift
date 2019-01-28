//
//  PDFDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import PDFKit

class PDFPreviewViewController: UIViewController {

    lazy var pdfView = PDFView()
    var note: Note!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(pdfView, at: 0)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        sendPDF()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
