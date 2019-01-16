//
//  LighteningVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import ContactsUI
import CoreLocation


extension SmartWritingViewController {
    
    @IBAction func tapCancel(_ sender: Any) {
        textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapClipboard(_ sender: Button) {
        
        if Pasteboard.general.hasStrings {
            textView.paste(nil)
        } else {
            transparentNavigationController?.show(message: "There's no text on Clipboard. 😅".loc, textColor: Color.white, color: Color.redNoti)
        }
    }
    
    @IBAction func tapLocation(_ sender: Button) {
        Access.locationRequest(from: self, manager: locationManager) { [weak self] in
            guard let self = self else { return }
            self.lookUpCurrentLocation(completionHandler: {(placemark) in
                if let address = placemark?.postalAddress {
                    let str = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).split(separator: "\n").reduce("", { (str, subStr) -> String in
                        guard str.count != 0 else { return String(subStr) }
                        return (str + " " + String(subStr))
                    })
                    
                    self.textView.insertText(str)
                } else {
                    Alert.warning(from: self, title: "GPS Error".loc, message: "Your device failed to get location.".loc)
                }
            })
            
        }
    }
    
    @IBAction func tapCheck(_ sender: Button) {
        //TODO: 현재 문단에 whitespace를 제외하고 텍스트가 없다면 바로 단축키와 띄어쓰기를 입력하고, 텍스트가 있다면 개행한 후, 단축키와 띄어쓰기를 인서트한다.
        let nsString = textView.text as NSString
        let paraRange = nsString.paragraphRange(for: textView.selectedRange)
        let paraString = nsString.substring(with: paraRange)
        let checkStr = (PianoBullet.userDefineForms.first?.shortcut ?? "-") + " "
        if paraString.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
            textView.insertText("\n" + checkStr)
        } else {
            textView.insertText(checkStr)
        }
    }
    
    @IBAction func tapTime(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            timeScrollView.isHidden = false
        } else {
            timeScrollView.isHidden = true
        }
        
    }
    
    @IBAction func tapContact(_ sender: Any) {
        
    }
    
    @IBAction func tapDeadline(_ sender: Any) {
        
    }
    
    @IBAction func tapSend(_ sender: Any) {
        guard let attrText = textView.attributedText, attrText.length != 0 else { return }
        let strArray = attrText.string.components(separatedBy: .newlines)
        let strs = strArray.map { (str) -> String in
            if let pianoBullet = PianoBullet(type: .value, text: str, selectedRange: NSRange(location: 0, length: 0)) {
                return (str as NSString).replacingCharacters(in: pianoBullet.range, with: pianoBullet.key)
            } else {
                return str
            }
        }
        //TODO: tags는 폴더가 만들어진 후에 뷰컨트롤러에 있는 폴더값을 대입해서 생성한다.
        // ex) create(content: ~~, folder: ~~)
        noteHandler?.create(content: strs.joined(separator: "\n"), tags: "", completion: nil)
        textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapEraseAll(_ sender: UIButton) {
        textView.text = ""
        textView.typingAttributes = Preference.defaultAttr
        textView.insertText("")
        sender.isEnabled = false
    }
    
    //TODO: dateFormatter로 short로 표현하기
    //현재 문단에 텍스트가 있다면, 띄어쓰기 앞에 붙이기
    //시간 뒤에 무조건 띄어쓰기 삽입하기
    
    @IBAction func tap5mTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 5)
    }
    
    @IBAction func tap10mTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 10)
    }
    
    @IBAction func tap30mTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 30)
    }
    
    @IBAction func tap1hTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 60)
    }
    
    @IBAction func tap3hTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 60 * 3)
    }
    
    @IBAction func tap1dTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 60 * 24)
    }
    
    @IBAction func tap2dTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 60 * 24 * 2)
    }
    
    @IBAction func tap7dTime(_ sender: Any) {
        insertTimeAndChangeViewsState(second: 60 * 60 * 24 * 7)
    }
    
    
}

extension SmartWritingViewController {
    
    private func insertTimeAndChangeViewsState(second: TimeInterval) {
        timeScrollView.isHidden = true
        timeBtn.isSelected = false
        insertTime(second: second)
    }
    
    private func insertTime(second: TimeInterval) {
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        let count = (textView.text as NSString).substring(with: paraRange).count
        
        let date = Date(timeIntervalSinceNow: second)
        let str = count != 0
            ? " " + DateFormatter.sharedInstance.string(from: date) + " "
            : DateFormatter.sharedInstance.string(from: date) + " "
        
        textView.insertText(str)
    }
}

extension SmartWritingViewController: CLLocationManagerDelegate {
    
    private func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
        -> Void ) {
        // Use the last reported location.
        if let lastLocation = locationManager.location {
            let geocoder = CLGeocoder()
            
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                                            completionHandler: { (placemarks, error) in
                                                if error == nil {
                                                    let firstLocation = placemarks?[0]
                                                    completionHandler(firstLocation)
                                                } else {
                                                    // An error occurred during geocoding.
                                                    completionHandler(nil)
                                                }
            })
        } else {
            // No location was available.
            completionHandler(nil)
        }
    }
    
    
}
