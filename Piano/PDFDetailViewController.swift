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
    
    let pdfView = PDFView()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotifications()
    }
    
    
    
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    

    @IBAction func tapSend(_ sender: Any) {
        Alert.warning(from: self, title: "준비중", message: "😿 조금만 더 기다려주세요!")
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
