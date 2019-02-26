//
//  ReceiptValidator+Helper.swift
//  Piano
//
//  Created by hoemoon on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ReceiptValidator {
    struct Loader {
        private let receiptURL = Bundle.main.appStoreReceiptURL
        private var isFoundReceipt: Bool {
            do {
                _ = try receiptURL?.checkResourceIsReachable()
                return true
            } catch {
                return false
            }
        }

        /// 로컬에 저장된 영수증을 반환합니다.
        ///
        /// - Returns: Data 타입의 영수증
        /// - Throws: 없으면 `.couldNotFindReceipt` 예외를 던집니다.
        func load() throws -> Data {
            if isFoundReceipt {
                do {
                    let data = try Data(contentsOf: receiptURL!)
                    return data
                } catch {
                    throw ReceiptValidationError.couldNotFindReceipt
                }
            }
            throw ReceiptValidationError.couldNotFindReceipt
        }
    }

    struct Extractor {
        /// OpenSSL을 이용해 PKCS7 컨테이너를 추출합니다.
        ///
        /// - Parameter data: `Loader`에서 반환된 영수증 데이터 객체
        /// - Returns: PKCS7 컨테이너
        /// - Throws: 실패시 `.emptyReceiptContents` 예외를 던집니다.
        func extractPKCS7Container(_ data: Data) throws -> UnsafeMutablePointer<pkcs7_st> {
            let bio = BIO_new(BIO_s_mem())
            BIO_write(bio, (data as NSData).bytes, Int32(data.count))
            let container = d2i_PKCS7_bio(bio, nil)

            guard container != nil else {
                throw ReceiptValidationError.emptyReceiptContents
            }

            let pkcs7DataTypeCode = OBJ_obj2nid(pkcs7_d_sign(container)?.pointee.contents.pointee.type)

            guard pkcs7DataTypeCode == NID_pkcs7_data else {
                throw ReceiptValidationError.emptyReceiptContents
            }
            return container!
        }
    }

    struct SignatureValidator {
        /// signature가 존재하는지 확인합니다.
        ///
        /// - Parameter container: PKCS7 컨테이너
        /// - Throws: signature가 없는 경우 `.receiptNotSigned` 예외를 던집니다
        func checkSignaturePresenece(_ container: UnsafeMutablePointer<pkcs7_st>) throws {

            guard OBJ_obj2nid(container.pointee.type) == NID_pkcs7_signed else {
                throw ReceiptValidationError.receiptNotSigned
            }
        }

        func checkSignatureAuthenticity(_ container: Container) throws {
            let appleRootCertificateX509 = try loadAppleRootCertificate()

            try verifyAuthenticity(appleRootCertificateX509, container: container)
        }

        /// 디스크에 저장된 인증서를 가져와서 X509 인증서로 반환합니다.
        ///
        /// - Returns: X509 인증서
        /// - Throws: 인증서가 없는 경우 `.appleRootCertificateNotFound` 예외를 던집니다.
        private func loadAppleRootCertificate() throws -> UnsafeMutablePointer<X509> {
            guard let url = Bundle.main.url(forResource: "AppleIncRootCertificate", withExtension: "cer") else {
                throw ReceiptValidationError.appleRootCertificateNotFound
            }
            do {
                let data = try Data(contentsOf: url)
                let bio = BIO_new(BIO_s_mem())
                BIO_write(bio, (data as NSData).bytes, Int32(data.count))
                return d2i_X509_bio(bio, nil)!
            } catch {
                throw ReceiptValidationError.appleRootCertificateNotFound
            }
        }

        /// X509 인증서를 이용해 PKCS7 컨테이너에 담긴 영수증의 signature를 검증합니다.
        ///
        /// - Parameters:
        ///   - x509Certificate: X509 인증서로 변환된 루트 인증서
        ///   - container: 영수증이 담긴 PKCS7 컨테이너
        /// - Throws: 검증에 실패한 경우 `.receiptSignatureInvalid` 예외를 던집니다.
        func verifyAuthenticity(_ x509Certificate: UnsafeMutablePointer<X509>, container: Container) throws {
            let store = X509_STORE_new()
            X509_STORE_add_cert(store, x509Certificate)

            OpenSSL_add_all_digests()

            if PKCS7_verify(container, nil, store, nil, nil, 0) != 1 {
                throw ReceiptValidationError.receiptSignatureInvalid
            }
        }
    }

    struct Parser {
        /// 영수증 swift로 struct로 바꿔주는 메서드
        ///
        /// - Parameter container: 영수증이 담긴 PKCS7 컨테이너
        /// - Returns: swift struct로 표현된 영수증
        /// - Throws: 실패시 `.malformedReceipt` 예외를 던진다.
        func parse(_ container: Container) throws -> ParsedReceipt {
            var bundleIdentifier: String?
            var bundleIdData: NSData?
            var appVersion: String?
            var opaqueValue: NSData?
            var sha1Hash: NSData?
            var inAppPurchaseReceipts = [ParsedInAppPurchaseReceipt]()
            var originalAppVersion: String?
            var receiptCreationDate: Date?
            var expirationDate: Date?

            guard let contents = container.pointee.d.sign.pointee.contents,
                let octets = contents.pointee.d.data else {
                    throw ReceiptValidationError.malformedReceipt
            }

            var currentASN1PayloadLocation = UnsafePointer(octets.pointee.data)
            let endOfPayload = currentASN1PayloadLocation!.advanced(by: Int(octets.pointee.length))

            var type = Int32(0)
            var xclass = Int32(0)
            var length = 0

            ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, Int(octets.pointee.length))

            guard type == V_ASN1_SET else {
                throw ReceiptValidationError.malformedReceipt
            }

            while currentASN1PayloadLocation! < endOfPayload {
                ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, currentASN1PayloadLocation!.distance(to: endOfPayload))

                guard type == V_ASN1_SEQUENCE else {
                    throw ReceiptValidationError.malformedReceipt
                }

                guard let attributeType = DecodeASN1Integer(startOfInt: &currentASN1PayloadLocation, length: currentASN1PayloadLocation!.distance(to: endOfPayload)) else {
                    throw ReceiptValidationError.malformedReceipt
                }

                guard DecodeASN1Integer(startOfInt: &currentASN1PayloadLocation, length: currentASN1PayloadLocation!.distance(to: endOfPayload)) != nil else {
                    throw ReceiptValidationError.malformedReceipt
                }

                ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, currentASN1PayloadLocation!.distance(to: endOfPayload))

                guard type == V_ASN1_OCTET_STRING else {
                    throw ReceiptValidationError.malformedReceipt
                }

                switch attributeType {
                case 2:
                    var startOfBundleId = currentASN1PayloadLocation
                    bundleIdData = NSData(bytes: startOfBundleId, length: length)
                    bundleIdentifier = DecodeASN1String(startOfString: &startOfBundleId, length: length)
                case 3:
                    var startOfAppVersion = currentASN1PayloadLocation
                    appVersion = DecodeASN1String(startOfString: &startOfAppVersion, length: length)
                case 4:
                    let startOfOpaqueValue = currentASN1PayloadLocation
                    opaqueValue = NSData(bytes: startOfOpaqueValue, length: length)
                case 5:
                    let startOfSha1Hash = currentASN1PayloadLocation
                    sha1Hash = NSData(bytes: startOfSha1Hash, length: length)
                case 17:
                    var startOfInAppPurchaseReceipt = currentASN1PayloadLocation
                    let iapReceipt = try parseInAppPurchaseReceipt(currentInAppPurchaseASN1PayloadLocation: &startOfInAppPurchaseReceipt, payloadLength: length)
                    inAppPurchaseReceipts.append(iapReceipt)
                case 12:
                    var startOfReceiptCreationDate = currentASN1PayloadLocation
                    receiptCreationDate = DecodeASN1Date(startOfDate: &startOfReceiptCreationDate, length: length)
                case 19:
                    var startOfOriginalAppVersion = currentASN1PayloadLocation
                    originalAppVersion = DecodeASN1String(startOfString: &startOfOriginalAppVersion, length: length)
                case 21:
                    var startOfExpirationDate = currentASN1PayloadLocation
                    expirationDate = DecodeASN1Date(startOfDate: &startOfExpirationDate, length: length)
                default:
                    break
                }

                currentASN1PayloadLocation = currentASN1PayloadLocation?.advanced(by: length)

            }
            return ParsedReceipt(
                bundleIdentifier: bundleIdentifier,
                bundleIdData: bundleIdData,
                appVersion: appVersion,
                opaqueValue: opaqueValue,
                sha1Hash: sha1Hash,
                inAppPurchaseReceipts: inAppPurchaseReceipts,
                originalAppVersion: originalAppVersion,
                receiptCreationDate: receiptCreationDate,
                expirationDate: expirationDate
            )
        }

        /// 영수증에 포함된 in-app결제에 대한 영수증을 swift struct로 반환하는 메서드
        func parseInAppPurchaseReceipt(currentInAppPurchaseASN1PayloadLocation: inout UnsafePointer<UInt8>?, payloadLength: Int) throws -> ParsedInAppPurchaseReceipt {

            var quantity: Int?
            var productIdentifier: String?
            var transactionIdentifier: String?
            var originalTransactionIdentifier: String?
            var purchaseDate: Date?
            var originalPurchaseDate: Date?
            var subscriptionExpirationDate: Date?
            var cancellationDate: Date?
            var webOrderLineItemId: Int?

            let endOfPayload = currentInAppPurchaseASN1PayloadLocation!.advanced(by: payloadLength)
            var type = Int32(0)
            var xclass = Int32(0)
            var length = 0

            ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, payloadLength)

            guard type == V_ASN1_SET else {
                throw ReceiptValidationError.malformedInAppPurchaseReceipt
            }

            while currentInAppPurchaseASN1PayloadLocation! < endOfPayload {

                ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload))

                guard type == V_ASN1_SEQUENCE else {
                    throw ReceiptValidationError.malformedInAppPurchaseReceipt
                }

                guard let attributeType = DecodeASN1Integer(startOfInt: &currentInAppPurchaseASN1PayloadLocation, length: currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload)) else {
                    throw ReceiptValidationError.malformedInAppPurchaseReceipt
                }

                guard DecodeASN1Integer(startOfInt: &currentInAppPurchaseASN1PayloadLocation, length: currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload)) != nil else {
                    throw ReceiptValidationError.malformedInAppPurchaseReceipt
                }

                ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload))

                // ASN1 Sequence value must be an ASN1 Octet String
                guard type == V_ASN1_OCTET_STRING else {
                    throw ReceiptValidationError.malformedInAppPurchaseReceipt
                }

                switch attributeType {
                case 1701:
                    var startOfQuantity = currentInAppPurchaseASN1PayloadLocation
                    quantity = DecodeASN1Integer(startOfInt: &startOfQuantity, length: length)
                case 1702:
                    var startOfProductIdentifier = currentInAppPurchaseASN1PayloadLocation
                    productIdentifier = DecodeASN1String(startOfString: &startOfProductIdentifier, length: length)
                case 1703:
                    var startOfTransactionIdentifier = currentInAppPurchaseASN1PayloadLocation
                    transactionIdentifier = DecodeASN1String(startOfString: &startOfTransactionIdentifier, length: length)
                case 1705:
                    var startOfOriginalTransactionIdentifier = currentInAppPurchaseASN1PayloadLocation
                    originalTransactionIdentifier = DecodeASN1String(startOfString: &startOfOriginalTransactionIdentifier, length: length)
                case 1704:
                    var startOfPurchaseDate = currentInAppPurchaseASN1PayloadLocation
                    purchaseDate = DecodeASN1Date(startOfDate: &startOfPurchaseDate, length: length)
                case 1706:
                    var startOfOriginalPurchaseDate = currentInAppPurchaseASN1PayloadLocation
                    originalPurchaseDate = DecodeASN1Date(startOfDate: &startOfOriginalPurchaseDate, length: length)
                case 1708:
                    var startOfSubscriptionExpirationDate = currentInAppPurchaseASN1PayloadLocation
                    subscriptionExpirationDate = DecodeASN1Date(startOfDate: &startOfSubscriptionExpirationDate, length: length)
                case 1712:
                    var startOfCancellationDate = currentInAppPurchaseASN1PayloadLocation
                    cancellationDate = DecodeASN1Date(startOfDate: &startOfCancellationDate, length: length)
                case 1711:
                    var startOfWebOrderLineItemId = currentInAppPurchaseASN1PayloadLocation
                    webOrderLineItemId = DecodeASN1Integer(startOfInt: &startOfWebOrderLineItemId, length: length)
                default:
                    break
                }

                currentInAppPurchaseASN1PayloadLocation = currentInAppPurchaseASN1PayloadLocation!.advanced(by: length)

            }

            return ParsedInAppPurchaseReceipt(
                quantity: quantity,
                productIdentifier: productIdentifier,
                transactionIdentifier: transactionIdentifier,
                originalTransactionIdentifier: originalTransactionIdentifier,
                purchaseDate: purchaseDate,
                originalPurchaseDate: originalPurchaseDate,
                subscriptionExpirationDate: subscriptionExpirationDate,
                cancellationDate: cancellationDate,
                webOrderLineItemId: webOrderLineItemId
            )
        }

        /// 포인터로부터 Int 타입으로 변환해주는 helper 메서드
        func DecodeASN1Integer(startOfInt intPointer: inout UnsafePointer<UInt8>?, length: Int) -> Int? {

            var type = Int32(0)
            var xclass = Int32(0)
            var intLength = 0

            ASN1_get_object(&intPointer, &intLength, &type, &xclass, length)

            guard type == V_ASN1_INTEGER else {
                return nil
            }

            let interger = c2i_ASN1_INTEGER(nil, &intPointer, intLength)
            let result = ASN1_INTEGER_get(interger)
            ASN1_INTEGER_free(interger)

            return result
        }

        /// 포인터로부터 String 타입으로 변환해주는 helper 메서드
        func DecodeASN1String(startOfString stringPointer: inout UnsafePointer<UInt8>?, length: Int) -> String? {

            var type = Int32(0)
            var xclass = Int32(0)
            var stringLength = 0

            ASN1_get_object(&stringPointer, &stringLength, &type, &xclass, length)

            if type == V_ASN1_UTF8STRING {
                let pointer = UnsafeMutableRawPointer(mutating: stringPointer!)
                return String(bytesNoCopy: pointer, length: stringLength, encoding: .utf8, freeWhenDone: false)
            }

            if type == V_ASN1_IA5STRING {
                let pointer = UnsafeMutableRawPointer(mutating: stringPointer!)
                return String(bytesNoCopy: pointer, length: stringLength, encoding: .ascii, freeWhenDone: false)
            }
            return nil
        }

        /// 포인터로부터 Date 타입으로 변환해주는 helper 메서드
        func DecodeASN1Date(startOfDate datePointer: inout UnsafePointer<UInt8>?, length: Int) -> Date? {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            if let dateString = DecodeASN1String(startOfString: &datePointer, length: length) {
                return formatter.date(from: dateString)
            }

            return nil
        }
    }
}
