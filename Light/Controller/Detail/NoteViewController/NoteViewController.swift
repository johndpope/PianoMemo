//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class NoteViewController: UIViewController {
    
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }
    
    @IBOutlet weak var textView: LightTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func add(_ sender: Any) {
        
    }
    
    private func setTextView() {
        if let text = note.content {
            DispatchQueue.global(qos: .userInteractive).async {
                let attrString = text.createFormatAttrString()
                DispatchQueue.main.async { [weak self] in
                    self?.textView.attributedText = attrString
                }
            }
        }
        
        if let date = note.modifiedDate {
            let string = DateFormatter.sharedInstance.string(from:date)
            self.textView.setDescriptionLabel(text: string)
        }
    }
    
}

extension NoteViewController {
    private func setNavigationBar(){
        tabBarController?.navigationItem.titleView = nil
        let actionBtn = BarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action(_:)))
        let shareBtn = BarButtonItem(image: #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:)))
        tabBarController?.navigationItem.setRightBarButtonItems([actionBtn, shareBtn], animated: true)
    }

}
