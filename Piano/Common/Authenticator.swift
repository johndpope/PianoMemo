//
//  Athenticator.swift
//  Piano
//
//  Created by 박주혁 on 30/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import LocalAuthentication

class Authenticator {

    /// parameters:
    ///  - reason: 암호를 물어보는 다이얼로그에 뜨는 메세지
    ///  - success: 인증 성공 시 호출
    ///  - failuer: 인증 실패 시 호출 (암호가 꺼져있는 경우 아래 notSet 호출)
    ///  - notSete(option): 아이폰 암호가 설정되어있지 않은 경우 호출
    class func requestAuth(reason: String, success: @escaping() -> Void, failure: @escaping(String) -> Void, notSet: @escaping() -> Void = {}) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use passcode".loc

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { isSuccess, error in
            if isSuccess {
                DispatchQueue.main.async {
                    success()
                }
                return
            }

            guard let error = error as? LAError else { return }
            if error.code == LAError.Code.passcodeNotSet {
                DispatchQueue.main.async {
                    notSet()
                }
            } else {
                DispatchQueue.main.async {
                    failure(error.localizedDescription)
                }
            }
        }
    }
}
