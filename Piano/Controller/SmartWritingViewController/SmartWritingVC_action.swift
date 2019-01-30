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
    
    @IBAction func tapEraseAll(_ sender: UIButton) {
        textView.text = ""
        textView.typingAttributes = Preference.defaultAttr
        textView.insertText("")
    }
    
    @IBAction func tapInfo(_ sender: UIButton) {
        let isHidden = sender.isSelected
        
        setHiddenGuideViews(isHidden: isHidden)
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
        insertCheck()
    }

    @IBAction func tapTime(_ sender: UIButton) {
        insertTime(second: 60 * 60 * 24)
    }

    @IBAction func tapExpiredTime(_ sender: Any) {

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

}

extension SmartWritingViewController {

    private func insertTimeAndChangeViewsState(second: TimeInterval) {
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
    
    private func insertCheck() {
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
