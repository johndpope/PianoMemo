//
//  NSNotificaiton.swift
//  Piano
//
//  Created by hoemoon on 12/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let resolveContent = NSNotification.Name("resolveContent")
    static let bypassList = NSNotification.Name("bypassList")
    static let popDetail = NSNotification.Name("popDetail")
    static let refreshTextAccessory = NSNotification.Name("refreshTextAccessory")

    static let balanceChange = NSNotification.Name("balanceChange")
    static let completeTransaction = NSNotification.Name("completeTransaction")

    static let displayCKErrorMessage = NSNotification.Name("displayCKErrorMessage")

    static let fetchDataFromRemote = NSNotification.Name("fetchDataFromRemote")
    static let didFinishHandleZoneChange = NSNotification.Name("didFinishHandleZoneChange")

    static let didStartMigration = NSNotification.Name("didStartMigration")
    static let didFinishMigration = NSNotification.Name("didFinishMigration")
}
