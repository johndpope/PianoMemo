//
//  TutorialEmojiListViewController.swift
//  Piano
//
//  Created by 박주혁 on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class TutorialEmojiListViewController: UIViewController {
    
    @IBOutlet weak var label0: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    
    var data: [Int] = [0]
    var labelArray: [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelArray.append(contentsOf: [label0, label1, label2, label3])
        updateView(with: data)
    }
    
    private func updateView(with data: [Int]) {
        for (index, label) in labelArray.enumerated() {
            let checked = data.contains(index)
            label.attributedText = strikethrough(checked, text: label.text!)
        }
    }
    
    private func checkIfDone(with data: [Int]) {
        if data.count == 4 {
            performSegue(withIdentifier: TutorialHighlightViewController.identifier, sender: nil)
        }
    }
    
    @IBAction func didTap(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            data.append(sender.tag)
        } else {
            guard let index = data.firstIndex(of: sender.tag) else {return}
            data.remove(at: index)
        }
        
        updateView(with: data)
        checkIfDone(with: data)
    }
    
    private func strikethrough(_ bool: Bool, text: String) -> NSAttributedString {
        if bool {
            let attri: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: 1,
                .strikethroughColor: UIColor.gray,
                .foregroundColor: UIColor.gray,
                .font: UIFont.preferredFont(forTextStyle: .body)
            ]
            return NSAttributedString(string: text, attributes: attri)
        }
        return NSAttributedString(string: text, attributes: nil)
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

