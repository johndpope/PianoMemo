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

struct ReceiptValidator {
    typealias Container = UnsafeMutablePointer<pkcs7_st>

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

        let rawDeviceIdentifierPointer = withUnsafePointer(to: &deviceIdentifier, { (unsafeDeviceIdentifierPointer: UnsafePointer<uuid_t?>) -> UnsafeRawPointer in
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
        var computedHash = [UInt8](repeating: 0, count: 20)
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
