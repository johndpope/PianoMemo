//
//  MailDetailViewController.swift
//  Light
//
//  Created by JangDoRi on 2018. 9. 5..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import WebKit

class MailDetailViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    var html: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let html = html {
            webView.loadHTMLString(html, baseURL: nil)
        } else {
            //...
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
