//
//  CloudeService+FetchErrorHandlable.swift
//  Piano
//
//  Created by hoemoon on 15/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CloudKit

/// fetch 중에 발생하는 에러를 다루기를 정의하는 프로토콜
protocol FetchErrorHandlable: class {
    var retriedErrorCodes: [Int] { get set }
    func handleError(error: Error?, completion: @escaping () -> Void)
}

extension CloudService: FetchErrorHandlable {
    /// 리모터 저장소에서 레코드를 fetch하는 도중에 발생하는 에러를 처리하는 메서드입니다.
    /// 각각의 에러 유형에 따라서 다르게 재시도 합니다.
    /// 에러 발생시 해당 에러를 기록합니다. 다시 해당 에러가 발생할 경우 재시도하지 않습니다.
    ///
    /// - Parameters:
    ///   - error: fetch 중에 발생한 에러 객체
    ///   - completion: completion handler
    func handleError(error: Error?, completion: @escaping () -> Void) {
        func flush() { retriedErrorCodes.removeAll() }

        guard let ckError = error as? CKError, !retriedErrorCodes.contains(ckError.errorCode) else { return }
        retriedErrorCodes.append(ckError.errorCode)

        switch ckError.code {
        case .changeTokenExpired:
            retryRequest(needRefreshToken: true) {
                if $0 { flush() }
                completion()
            }
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            if let number = ckError.userInfo[CKErrorRetryAfterKey] as? NSNumber {
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(truncating: number)) { [weak self] in
                    guard let self = self else { return }
                    self.retryRequest(completion: { success in
                        if success { flush() }
                        completion()
                    })
                }
            }
        case .networkFailure, .networkUnavailable, .serverResponseLost:
            retryRequest { success in
                if success { flush() }
                completion()
            }
        default:
            completion()
        }
    }

    /// 실제로 fetch를 재시도하는 메서드 입니다.
    private func retryRequest(
        error: CKError? = nil,
        needRefreshToken: Bool = false,
        completion: @escaping (Bool) -> Void) {

        fetchChanges(in: .private, needRefreshToken: needRefreshToken) { [weak self] in
            guard let self = self, $0 == true else { completion(false); return }
            self.fetchChanges(in: .shared, needRefreshToken: needRefreshToken) { success in
                if success { completion(true) }
            }
        }
    }
}
