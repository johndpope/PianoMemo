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
    private var accessoryMessageOriginInfo: (String?, Color?)
    @IBOutlet weak var textField: EmojiTextField!
    @IBOutlet var accessoryView: TagPickerAccessoryView!
    @IBOutlet var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        accessoryMessageOriginInfo = (accessoryView.messageLabel.text, accessoryView.messageLabel.textColor)
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
        dismiss(animated: true) {
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
        masterViewController?.registerAllNotification()
        dismiss(animated: true, completion: nil)
    }

}

extension TagPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return KeyValueStore.default.emojis.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TagCell.reuseIdentifier,
            for: indexPath) as? TagCell {

            cell.label.text = KeyValueStore.default.emojis[indexPath.item]
            return cell
        }

        return UICollectionViewCell()
    }

}

extension TagPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //TODO: 삭제해야함
        var emojiTags = KeyValueStore.default.emojis
        emojiTags.remove(at: indexPath.item)
        KeyValueStore.default.updateEmojis(newValue: emojiTags)
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

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
        //백스페이스이면 무시
        guard string.count != 0 else { return false }
        //TODO: 입력 문자열이 이모지가 아니거나 emojiTags에 포함되어있다면 노티 띄워주기
        guard string.containsEmoji else {
            updateAccessoryMessage(message: "Only emojis are available".loc, color: Color.redNoti)
            return false
        }

        guard !KeyValueStore.default.emojis.contains(string) else {
            updateAccessoryMessage(message: "Already added!".loc, color: Color.redNoti)
            return false
        }

        var emojiTags = KeyValueStore.default.emojis
        emojiTags.insert(string, at: 0)
        KeyValueStore.default.updateEmojis(newValue: emojiTags)
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.insertItems(at: [indexPath])

        return false
    }
}

extension TagPickerViewController {
    private func updateAccessoryMessage(message: String, color: UIColor) {
        accessoryView.messageLabel.text = message
        accessoryView.messageLabel.textColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.accessoryView.messageLabel.text = self.accessoryMessageOriginInfo.0
            self.accessoryView.messageLabel.textColor = self.accessoryMessageOriginInfo.1
        }
    }
}
