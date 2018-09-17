//
//  Constant.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CloudKit

/// "CloudZone"
public let ZONE_ID = CKRecordZone.ID(zoneName: "CloudZone", ownerName: CKCurrentUserDefaultName)

/// "UserKey"
internal let USER_KEY = "UserKey"

/// "PrivateDatabase"
internal let PRIVATE_DB_ID = "PrivateDatabase"
/// "SharedDatabase"
internal let SHARED_DB_ID = "SharedDatabase"
/// "PublicDatabase"
internal let PUBLIC_DB_ID = "PublicDatabase"
/// "CloudDatabase"
internal let DATABASE_DB_ID = "CloudDatabase"

/// "FetchContext"
internal let FETCH_CONTEXT = "FetchContext"
/// "FetchContext"
internal let LOCAL_CONTEXT = "LocalContext"

/// "RecordData"
public let KEY_RECORD_DATA = "ckMetaData"
/// "RecordName"
public let KEY_RECORD_NAME = "recordName"
/// "Attribute name for content"
public let KEY_RECORD_TEXT = "content"

/// "cloudkit.share"
internal let SHARE_RECORD_TYPE = "cloudkit.share"
/// "CloudToken"
internal let KEY_TOKEN = "CloudToken"

