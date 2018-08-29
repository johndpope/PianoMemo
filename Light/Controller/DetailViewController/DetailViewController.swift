//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    
    @IBOutlet weak var textView: LightTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let note = (tabBarController as? DetailTabBarViewController)?.note else { return }
        setTextView(note: note)
        
        
        let barButton = BarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
        navigationItem.setRightBarButton(barButton, animated: true)
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
