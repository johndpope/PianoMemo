//
//  CNContact_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 6..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import Contacts

//extension CNMutableContact {
//    internal func modify(to contactDetected: String.Contact) {
//        self.familyName = contactDetected.familyName
//        self.givenName = contactDetected.givenName
//        
//        self.phoneNumbers = []
//        contactDetected.phones.forEach { (phone) in
//            let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberiPhone,
//                                             value: CNPhoneNumber(stringValue: phone))
//            phoneNumbers.append(phoneNumber)
//        }
//        
//        self.emailAddresses = []
//        
//        contactDetected.mails.forEach { (mail) in
//            let workEmail = CNLabeledValue(label:CNLabelWork, value: mail as NSString)
//            emailAddresses.append(workEmail)
//        }
//        
//    }
//}
