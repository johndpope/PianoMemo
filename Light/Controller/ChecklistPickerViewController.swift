//
//  ChecklistPickerViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

class ChecklistPickerViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    @IBOutlet weak var girl: UIButton!
    @IBOutlet weak var boy: UIButton!
    @IBOutlet weak var yellow: UIButton!
    @IBOutlet weak var white: UIButton!
    @IBOutlet weak var normal: UIButton!
    @IBOutlet weak var lightBrown: UIButton!
    @IBOutlet weak var darkBrown: UIButton!
    @IBOutlet weak var black: UIButton!
    
    @IBOutlet var buttons: [UIButton]!
    
    @IBOutlet weak var nextButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.shadowImage = UIImage()
        
        
        if let preference = self.preference() {
            selectButtons(preference: preference)
        }
    }
    
    internal func setCancel() {
        let btn = BarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.setLeftBarButton(btn, animated: false)
    }
    
    @objc func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    private func selectButtons(preference: Preference) {
        let isGirl = buttons.contains(where: { (button) -> Bool in
            guard let title = button.title(for: .normal), let checkOff = preference.checklistOff else { return false }
            return title == checkOff
        })
        
        if isGirl {
            girl(girl)
        } else {
            boy(boy)
        }
        
        buttons.forEach {
            if let title = $0.title(for: .normal),
                let checkOff = preference.checklistOff,
                title == checkOff {
                $0.isSelected = true
            }
        }
        
        
    }
    
    private func preference() -> Preference? {
        let preferenceRequest: NSFetchRequest<Preference> = Preference.fetchRequest()
        do {
            guard let preference = try context.fetch(preferenceRequest).first else { return nil }
            return preference
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let des = segue.destination as? ListPickerViewController {
            des.context = context
            
            let selectedButton = buttons.filter{ $0.isSelected }.first
            if let checklistOff = selectedButton?.title(for: .normal),
                let checklistOn = selectedButton?.title(for: .selected) {
                des.checklistOn = checklistOn
                des.checklistOff = checklistOff
            }
        }
        
        
    }
    
    @IBAction func girl(_ sender: UIButton) {
        sender.isSelected = true
        boy.isSelected = false
        
        yellow.setTitle("🙅‍♀️", for: .normal)
        yellow.setTitle("🙆‍♀️", for: .selected)
        white.setTitle("🙅🏻‍♀️", for: .normal)
        white.setTitle("🙆🏻‍♀️", for: .selected)
        normal.setTitle("🙅🏼‍♀️", for: .normal)
        normal.setTitle("🙆🏼‍♀️", for: .selected)
        lightBrown.setTitle("🙅🏽‍♀️", for: .normal)
        lightBrown.setTitle("🙆🏽‍♀️", for: .selected)
        darkBrown.setTitle("🙅🏾‍♀️", for: .normal)
        darkBrown.setTitle("🙆🏾‍♀️", for: .selected)
        black.setTitle("🙅🏿‍♀️", for: .normal)
        black.setTitle("🙆🏿‍♀️", for: .selected)
        
//        setNextBtnTitle()
        
    }
    
//    private func setNextBtnTitle() {
//        let titleSelected = buttons.filter { $0.isSelected }.first?.title(for: .normal)
//        if let title = titleSelected {
//            nextButton.titleLabel?.text = "@을 입력하면 \(title)"
//        }
//    }
    
    
    @IBAction func boy(_ sender: UIButton) {
        sender.isSelected = true
        girl.isSelected = false
        
        yellow.setTitle("🙅‍♂️", for: .normal)
        yellow.setTitle("🙆‍♂️", for: .selected)
        white.setTitle("🙅🏻‍♂️", for: .normal)
        white.setTitle("🙆🏻‍♂️", for: .selected)
        normal.setTitle("🙅🏼‍♂️", for: .normal)
        normal.setTitle("🙆🏼‍♂️", for: .selected)
        lightBrown.setTitle("🙅🏽‍♂️", for: .normal)
        lightBrown.setTitle("🙆🏽‍♂️", for: .selected)
        darkBrown.setTitle("🙅🏾‍♂️", for: .normal)
        darkBrown.setTitle("🙆🏾‍♂️", for: .selected)
        black.setTitle("🙅🏿‍♂️", for: .normal)
        black.setTitle("🙆🏿‍♂️", for: .selected)
        
//        setNextBtnTitle()
    }
    
    
    @IBAction func yellow(_ sender: UIButton) {
        yellow.isSelected = true
        white.isSelected = false
        normal.isSelected = false
        lightBrown.isSelected = false
        darkBrown.isSelected = false
        black.isSelected = false
        
//        setNextBtnTitle()
    }
    
    @IBAction func white(_ sender: UIButton) {
        yellow.isSelected = false
        white.isSelected = true
        normal.isSelected = false
        lightBrown.isSelected = false
        darkBrown.isSelected = false
        black.isSelected = false
        
//        setNextBtnTitle()
    }
    
    @IBAction func normal(_ sender: UIButton) {
        yellow.isSelected = false
        white.isSelected = false
        normal.isSelected = true
        lightBrown.isSelected = false
        darkBrown.isSelected = false
        black.isSelected = false
        
//        setNextBtnTitle()
    }
    
    @IBAction func lightBrown(_ sender: UIButton) {
        yellow.isSelected = false
        white.isSelected = false
        normal.isSelected = false
        lightBrown.isSelected = true
        darkBrown.isSelected = false
        black.isSelected = false
        
//        setNextBtnTitle()
    }
    
    @IBAction func darkBrown(_ sender: UIButton) {
        yellow.isSelected = false
        white.isSelected = false
        normal.isSelected = false
        lightBrown.isSelected = false
        darkBrown.isSelected = true
        black.isSelected = false
        
//        setNextBtnTitle()
    }
    
    @IBAction func black(_ sender: UIButton) {
        yellow.isSelected = false
        white.isSelected = false
        normal.isSelected = false
        lightBrown.isSelected = false
        darkBrown.isSelected = false
        black.isSelected = true
        
//        setNextBtnTitle()
    }
    
}
