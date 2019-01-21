//
//  PDFDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import PDFKit

class PDFDetailViewController: UIViewController {

    lazy var pdfView = PDFView()
    var data: Data!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        pdfView.document = PDFDocument(data: data)
        pdfView.scaleFactor = view.bounds.width / 595.2
        pdfView.maxScaleFactor = 1.5
        pdfView.minScaleFactor = view.bounds.width / 700
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    @IBAction func tapSend(_ sender: UIBarButtonItem) {
        saveFile { [weak self] url in
            guard let self = self else { return }
            if let url = url {
                let controller = UIActivityViewController(
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension PDFDetailViewController {
    private func saveFile(completion: @escaping (URL?) -> Void) {
        guard let document = pdfView.document else { return }
        do {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let fileURL = documentDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
            if document.write(to: fileURL) {
                completion(fileURL)
            } else {
                completion(nil)
            }

        } catch {
            completion(nil)
        }
    }

    private func removeFile(url: URL?) {
        guard let url = url else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error)
        }
    }
}
