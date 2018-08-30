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
        
        setTextView(note: note)
        setNavigationBar()
    }
    
    @IBAction func add(_ sender: Any) {
        
    }
    
    private func setTextView(note: Note) {
        if let text = note.content {
            DispatchQueue.main.async { [weak self] in
                let attrString = NSAttributedString(string: text, attributes: Preference.defaultAttr)
                self?.textView.attributedText = attrString
                self?.textView.convertBulletAllParagraphIfNeeded()
                
                if let date = note.modifiedDate {
                    let string = DateFormatter.sharedInstance.string(from:date)
                    self?.textView.setDescriptionLabel(text: string)
                }
            }
            
            
        }
    }
    
    
}

extension NoteViewController {
    private func setNavigationBar(){
        let actionBtn = BarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action(_:)))
        let shareBtn = BarButtonItem(image: #imageLiteral(resourceName: "check"), style: .plain, target: self, action: #selector(addPeople(_:)))
        tabBarController?.navigationItem.setRightBarButtonItems([actionBtn, shareBtn], animated: true)
    }

}
