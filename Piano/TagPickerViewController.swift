//
//  TagPickerViewController.swift
//  Piano
//
//  Created by Kevin Kim on 15/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TagPickerViewController: UIViewController {

    //modal로 할 때에는 viewWillAppear가 호출되지 않기 때문에 참조해서 registerNoti 해줘야함
    weak var masterViewController: MasterViewController?
    @IBOutlet weak var textField: EmojiTextField!
    @IBOutlet var accessoryView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    weak var storageService: StorageService!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let emojiKeyboard = UITextInputMode.activeInputModes.filter { $0.primaryLanguage == "emoji" }
        if emojiKeyboard.count == 0 {
            let emptyInputView = view.createSubviewIfNeeded(EmptyInputView.self)
            emptyInputView?.completionHandler = { [weak self] in
                self?.textField.inputView = nil
                self?.textField.resignFirstResponder()
                self?.masterViewController?.registerAllNotification()
                self?.dismiss(animated: true, completion: nil)

            }
            textField.inputView = emptyInputView
            textField.becomeFirstResponder()
        } else {
            textField.inputAccessoryView = accessoryView
            textField.becomeFirstResponder()
        }
    }
    
    @IBAction func tapDone(_ sender: Any) {
        textField.resignFirstResponder()
        masterViewController?.registerAllNotification()
        dismiss(animated: true, completion: nil)
    }
    
}

extension TagPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storageService.local.emojiTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCell.reuseIdentifier, for: indexPath) as! TagCell
        cell.label.text = storageService.local.emojiTags[indexPath.item]
        
        return cell
    }
    
    
}

extension TagPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //TODO: 삭제해야함
        var emojiTags = storageService.local.emojiTags
        emojiTags.remove(at: indexPath.item)
        storageService.local.emojiTags = emojiTags
        collectionView.deleteItems(at: [indexPath])
    }
}

extension TagPickerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        masterViewController?.registerAllNotification()
        dismiss(animated: true, completion: nil)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //백스페이스이면 무시
        guard string.count != 0 else { return false }
        //TODO: 입력 문자열이 이모지가 아니거나 emojiTags에 포함되어있다면 노티 띄워주기
        guard string.containsEmoji else {
            (navigationController as? TransParentNavigationController)?.show(message: "이모지만 입력해주세요".loc, color: Color.redNoti)
            return false
        }
        
        guard !storageService.local.emojiTags.contains(string) else {
            (navigationController as? TransParentNavigationController)?.show(message: "이미 추가되어 있어요!".loc, color: Color.redNoti)
            return false
        }
        
        var emojiTags = storageService.local.emojiTags
        emojiTags.append(string)
        storageService.local.emojiTags = emojiTags
        let indexPath = IndexPath(item: collectionView.numberOfItems(inSection: 0), section: 0)
        collectionView.insertItems(at: [indexPath])
        
        return false
    }
}