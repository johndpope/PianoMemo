//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class DetailViewController: UIViewController {
    
    var note: Note! {
        return (tabBarController as? DetailTabBarViewController)?.note
    }


    
    @IBOutlet weak var textView: LightTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

extension DetailViewController {
    private func setHighlightBarButton() {
        let barButton = BarButtonItem(title: "🖍", style: .plain, target: self, action: #selector(highlight(_:)))
        navigationItem.setRightBarButton(barButton, animated: true)

    }
    
    @IBAction func highlight(_ sender: Any) {
        setDoneBarButton()
        
    }
    
    private func setDoneBarButton() {
        let barButton = BarButtonItem(title: "🖌", style: .plain, target: self, action: #selector(highlight(_:)))
        navigationItem.setRightBarButton(barButton, animated: true)
        navigationItem.leftItemsSupplementBackButton = false
    }
    
    @IBAction func done(_ sender: Any) {
        setHighlightBarButton()
    }
}
