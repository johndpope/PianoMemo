//
//  ContactSuggestion.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Contacts


// 연락처를 추천하는 코드입니다.

//private func requestSuggestions() {
//    let keys: [CNKeyDescriptor] = [
//        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
//        CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName),
//        CNContactPhoneNumbersKey as CNKeyDescriptor,
//        CNContactEmailAddressesKey as CNKeyDescriptor,
//        ]
//    guard let noteContent = note.content else { return }
//
//    let noteTokens = noteContent.tokenzied
//    let integerableToken = noteTokens.filter { Int($0) != nil }.joined()
//
//    var contacts = [CNContact]()
//
//    let request = CNContactFetchRequest(keysToFetch: keys)
//    try? contactStore.enumerateContacts(with: request) { contact, pointer in
//        var didAppendContact = false
//
//        if let fullName = CNContactFormatter.string(from: contact, style: .fullName) {
//            let nameTokens = fullName.tokenzied
//            for token in noteTokens {
//                if nameTokens.contains(token) {
//                    contacts.append(contact)
//                    didAppendContact = true
//                    break
//                }
//            }
//        }
//
//        if didAppendContact == false,
//            let phoneticFullName = CNContactFormatter.string(from: contact, style: .phoneticFullName) {
//            let nameTokens = phoneticFullName.tokenzied
//            for token in noteTokens {
//                if nameTokens.contains(token) {
//                    contacts.append(contact)
//                    didAppendContact = true
//                    break
//                }
//            }
//        }
//
//        // (011) 111-1111 형태로 저장된 전화 번호는 스트링 토큰 형태로 다룰 수 있지만,
//        // 111222333 형태로 저장된 전화 번호는 다른 방법을 써야 한다.
//        // 노트 전체의 숫자를 스트링으로 만들고, 스트링 range를 사용해서 검색한다.
//        if didAppendContact == false {
//            let numberStringRepresentations = contact.phoneNumbers
//                .map { ($0.value as CNPhoneNumber) }
//                .flatMap { $0.stringValue.components(separatedBy: .punctuationCharacters)
//                    .filter { $0.count > 0 }
//                    .map { $0.trimmingCharacters(in: .whitespaces) }
//            }
//
//            let numberSet = Set(numberStringRepresentations)
//            var containCounter = 0
//
//            // (011) 111-1111로 저장된 경우
//            // 일치하는 토큰이 두 개 이상이면 추천할 연락처로 판단한다.
//            for token in noteTokens {
//                if numberSet.contains(token) {
//                    containCounter += 1
//                }
//                if containCounter > 1 {
//                    contacts.append(contact)
//                    didAppendContact = true
//                    break
//                }
//            }
//
//            // 111222333 형태로 저장된 경우
//            if didAppendContact == false {
//                for number in numberSet {
//                    if integerableToken.range(of: number) != nil {
//                        contacts.append(contact)
//                        didAppendContact = true
//                        break
//                    } else if number.range(of: integerableToken) != nil {
//                        contacts.append(contact)
//                        didAppendContact = true
//                        break
//                    }
//                }
//            }
//        }
//
//        if didAppendContact == false {
//            let usernameComponents = contact.emailAddresses
//                .compactMap { ($0.value as NSString)
//                    .components(separatedBy: "@")
//                    .first
//                }
//                .flatMap { $0.components(separatedBy: .punctuationCharacters) }
//
//            for token in noteTokens {
//                if usernameComponents.contains(token) {
//                    contacts.append(contact)
//                    break
//                }
//            }
//        }
//    }
//
//    DispatchQueue.main.async {
//        // TODO: 추천 결과 이용해서 UI 업데이트 하기
//    }
//    print("\n추천할 연락처 갯수: \(contacts.count)")
//    print(noteTokens)
//    print(contacts.map { $0.givenName })
//}
