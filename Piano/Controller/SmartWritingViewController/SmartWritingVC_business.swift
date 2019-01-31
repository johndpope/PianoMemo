//
//  SmartWritingVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 30/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import Contacts
import EventKit

extension SmartWritingViewController {
    internal func setRecommandViews(_ newValue: Recommandable?) {
        if newValue is EKReminder {
            recommandReminderView.data = newValue
            recommandEventView.data = nil
            recommandContactView.data = nil
            recommandAddressView.data = nil
            setHiddenGuideViews(isHidden: true)
        } else if newValue is EKEvent {
            recommandEventView.data = newValue
            recommandReminderView.data = nil
            recommandContactView.data = nil
            recommandAddressView.data = nil
            setHiddenGuideViews(isHidden: true)
        } else if let contact = newValue as? CNContact, contact.postalAddresses.count != 0 {
            recommandAddressView.data = newValue
            recommandContactView.data = nil
            recommandEventView.data = nil
            recommandReminderView.data = nil
            setHiddenGuideViews(isHidden: true)
        } else if let contact = newValue as? CNContact,
            contact.postalAddresses.count == 0 {
            recommandContactView.data = newValue
            recommandAddressView.data = nil
            recommandReminderView.data = nil
            recommandEventView.data = nil
            setHiddenGuideViews(isHidden: true)
        } else {
            recommandContactView.data = nil
            recommandReminderView.data = nil
            recommandEventView.data = nil
            recommandAddressView.data = nil
        }
    }

    internal func getRecommandData() -> Recommandable? {
        if let data = recommandReminderView.data {
            return data
        } else if let data = recommandEventView.data {
            return data
        } else if let data = recommandContactView.data {
            return data
        } else if let data = recommandAddressView.data {
            return data
        } else {
            return nil
        }
    }

    internal func setHiddenGuideViews(isHidden: Bool) {
        suggestionGuideView.isHidden = isHidden
        suggestionGuideButton.isSelected = !isHidden
    }

    internal func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Responder.keyboardWillShowNotification, object: nil)
    }

    internal func unRegisterAllNotification() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[Responder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }

        bottomViewBottomAnchor.constant = kbHeight
    }

    internal func setupRecommandViews() {
        recommandEventView.setup(viewController: self, textView: textView)
        recommandAddressView.setup(viewController: self, textView: textView)
        recommandContactView.setup(viewController: self, textView: textView)
        recommandReminderView.setup(viewController: self, textView: textView)
    }

    internal func setLocation(to locationButton: Button) {
        lookUpCurrentLocation(completionHandler: {(placemark) in
            if let address = placemark?.postalAddress {
                let str = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).split(separator: "\n").reduce("", { (str, subStr) -> String in
                    guard str.count != 0 else { return String(subStr) }
                    return (str + " " + String(subStr))
                })

                locationButton.setTitle("📍 " + str, for: .normal)
            } else {
                Alert.warning(from: self, title: "GPS Error".loc, message: "Your device failed to get location.".loc)
            }
        })
    }

    internal func insertTimeAndChangeViewsState(second: TimeInterval) {
        insertTime(second: second)
    }

    internal func insertTime(second: TimeInterval) {
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        let count = (textView.text as NSString).substring(with: paraRange).count

        let date = Date(timeIntervalSinceNow: second)
        let str = count != 0
            ? " " + DateFormatter.sharedInstance.string(from: date) + " "
            : DateFormatter.sharedInstance.string(from: date) + " "

        textView.insertText(str)
    }

    internal func insertCheck() {
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

    internal func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
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
