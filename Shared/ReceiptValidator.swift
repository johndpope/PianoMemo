//
//  ReceiptValidator.swift
//  Piano
//
//  Created by hoemoon on 13/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//
import Foundation
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import IOKit
import OpenSSL
#endif

extension StoreService {
    fileprivate typealias Container = UnsafeMutablePointer<pkcs7_st>

    enum ReceiptValidationResult {
        case success(ParsedReceipt)
        case error(ReceiptValidationError)
    }

    enum ReceiptValidationError: Error {
        case couldNotFindReceipt
        case emptyReceiptContents
        case receiptNotSigned
        case appleRootCertificateNotFound
        case receiptSignatureInvalid
        case malformedReceipt
        case malformedInAppPurchaseReceipt
        case incorrectHash
    }

    struct ParsedReceipt {
        let bundleIdentifier: String?
        let bundleIdData: NSData?
        let appVersion: String?
        let opaqueValue: NSData?
        let sha1Hash: NSData?
        let inAppPurchaseReceipts: [ParsedInAppPurchaseReceipt]?
        let originalAppVersion: String?
        let receiptCreationDate: Date?
        let expirationDate: Date?
    }

    struct ParsedInAppPurchaseReceipt {
        let quantity: Int?
        let productIdentifier: String?
        let transactionIdentifier: String?
        let originalTransactionIdentifier: String?
        let purchaseDate: Date?
        let originalPurchaseDate: Date?
        let subscriptionExpirationDate: Date?
        let cancellationDate: Date?
        let webOrderLineItemId: Int?
    }

    struct ReceiptValidator {
        private let loader = Loader()
        private let extractor = Extractor()
        private let validator = SignatureValidator()
        private let parser = Parser()

        func validate() -> ReceiptValidationResult {
            do {
                let data = try loader.load()
                let container = try extractor.extractPKCS7Container(data)

                try validator.checkSignaturePresenece(container)
                try validator.checkSignatureAuthenticity(container)

                let parsed = try parser.parse(container)
                try validateHash(receipt: parsed)
                return .success(parsed)
            } catch {
                return .error(error as! ReceiptValidationError)
            }
        }

        private func deviceIdentifierData() -> NSData? {
            #if os(macOS)

            var master_port = mach_port_t()
            var kernResult = IOMasterPort(mach_port_t(MACH_PORT_NULL), &master_port)

            guard kernResult == KERN_SUCCESS else {
                return nil
            }

            guard let matchingDict = IOBSDNameMatching(master_port, 0, "en0") else {
                return nil
            }

            var iterator = io_iterator_t()
            kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator)
            guard kernResult == KERN_SUCCESS else {
                return nil
            }

            var macAddress: NSData?
            while true {
                let service = IOIteratorNext(iterator)
                guard service != 0 else { break }

                var parentService = io_object_t()
                kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService)

                if kernResult == KERN_SUCCESS {
                    macAddress = IORegistryEntryCreateCFProperty(parentService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? NSData
                    IOObjectRelease(parentService)
                }

                IOObjectRelease(service)
            }

            IOObjectRelease(iterator)
            return macAddress

            #endif

            #if os(iOS) // iOS, watchOS, tvOS

            var deviceIdentifier = UIDevice.current.identifierForVendor?.uuid

            let rawDeviceIdentifierPointer = withUnsafePointer(to: &deviceIdentifier, {
                (unsafeDeviceIdentifierPointer: UnsafePointer<uuid_t?>) -> UnsafeRawPointer in
                return UnsafeRawPointer(unsafeDeviceIdentifierPointer)
            })

            return NSData(bytes: rawDeviceIdentifierPointer, length: 16)

            #endif
        }

        private func validateHash(receipt: ParsedReceipt) throws {
            // Make sure that the ParsedReceipt instances has non-nil values needed for hash comparison
            guard let receiptOpaqueValueData = receipt.opaqueValue else { throw ReceiptValidationError.incorrectHash }
            guard let receiptBundleIdData = receipt.bundleIdData else { throw ReceiptValidationError.incorrectHash }
            guard let receiptHashData = receipt.sha1Hash else { throw ReceiptValidationError.incorrectHash }

            guard let deviceIdentifierData = self.deviceIdentifierData() else {
                throw ReceiptValidationError.malformedReceipt
            }

            // Compute the hash for your app & device

            // Set up the hasing context
            var computedHash = Array<UInt8>(repeating: 0, count: 20)
            var sha1Context = SHA_CTX()

            SHA1_Init(&sha1Context)
            SHA1_Update(&sha1Context, deviceIdentifierData.bytes, deviceIdentifierData.length)
            SHA1_Update(&sha1Context, receiptOpaqueValueData.bytes, receiptOpaqueValueData.length)
            SHA1_Update(&sha1Context, receiptBundleIdData.bytes, receiptBundleIdData.length)
            SHA1_Final(&computedHash, &sha1Context)

            let computedHashData = NSData(bytes: &computedHash, length: 20)

            // Compare the computed hash with the receipt's hash
            guard computedHashData.isEqual(to: receiptHashData as Data) else { throw ReceiptValidationError.incorrectHash }
        }

    }

    private struct Loader {
        private let receiptURL = Bundle.main.appStoreReceiptURL
        private var isFoundReceipt: Bool {
            do {
                _ = try receiptURL?.checkResourceIsReachable()
                return true
            } catch {
                return false
            }
        }

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

    private struct Extractor {
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

    private struct SignatureValidator {
        func checkSignaturePresenece(_ container: UnsafeMutablePointer<pkcs7_st>) throws {

            guard OBJ_obj2nid(container.pointee.type) == NID_pkcs7_signed else {
                throw ReceiptValidationError.receiptNotSigned
            }
        }

        func checkSignatureAuthenticity(_ container: Container) throws {
            let appleRootCertificateX509 = try loadAppleRootCertificate()

            try verifyAuthenticity(appleRootCertificateX509, container: container)
        }

        func loadAppleRootCertificate() throws -> UnsafeMutablePointer<X509> {
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

        func verifyAuthenticity(_ x509Certificate: UnsafeMutablePointer<X509>, container: Container) throws {
            let store = X509_STORE_new()
            X509_STORE_add_cert(store, x509Certificate)

            OpenSSL_add_all_digests()

            if PKCS7_verify(container, nil, store, nil, nil, 0) != 1 {
                throw ReceiptValidationError.receiptSignatureInvalid
            }
        }
    }

    private struct Parser {
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
