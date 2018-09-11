//
//  MainNSViewController.swift
//  LightMac
//
//  Created by hoemoon on 10/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class MainNSViewController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.font = NSFont.systemFont(ofSize: 15)
    }
}
