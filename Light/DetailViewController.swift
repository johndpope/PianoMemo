//
//  DetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
enum DataType: Int {
    case reminder = 0
    case calendar = 1
    case photo = 2
    case mail = 3
    case contact = 4
}

class DetailViewController: UIViewController {
    
    var note: Note!
    @IBOutlet weak var textView: LightTextView!
    @IBOutlet weak var bottomView: UIView!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    var kbHeight: CGFloat!
    @IBOutlet var bottomButtons: [UIButton]!
    @IBOutlet weak var bottomViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet var containerViews: [UIView]!

    override func viewDidLoad() {
        super.viewDidLoad()
        setTextView()
        setNavigationBar(isTyping: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unRegisterKeyboardNotification()
    }

}

extension DetailViewController {

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
        
        textView.contentInset.bottom = bottomViewHeight
        textView.scrollIndicatorInsets.bottom = bottomViewHeight
    }
    
    internal func setNavigationBar(isTyping: Bool){
        var btns: [BarButtonItem] = []
        if isTyping {
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
        }
        
        btns.append(BarButtonItem(image: #imageLiteral(resourceName: "highlighter"), style: .plain, target: self, action: #selector(highlight(_:))))
        btns.append(BarButtonItem(image: #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:))))
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
}
