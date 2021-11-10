//
//  RSUtils.swift
//  Rudder
//
//  Created by Desu Sai Venkat on 06/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation
import WebKit
import SQLite3

func logDebug(_ message: String) {
    RSClient.shared.logger.logDebug(message: message)
}

func logError(_ message: String) {
    RSClient.shared.logger.logError(message: message)
}

func logVerbose(_ message: String) {
    RSClient.shared.logger.logVerbose(message: message)
}

func logInfo(_ message: String) {
    RSClient.shared.logger.logInfo(message: message)
}

func logWarn(_ message: String) {
    RSClient.shared.logger.logWarn(message: message)
}

struct RSUtils {
    static func getDateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter.string(from: date)
    }
    
    static func getTimestampString() -> String {
        return getDateString(date: Date())
    }

    static func getDBPath() -> String {
        let urlDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let fileUrl = urlDirectory.appendingPathComponent("rl_persistence.sqlite")
        return fileUrl.path
    }
    
    static func openDatabase() -> OpaquePointer? {
        var db: OpaquePointer?
        if sqlite3_open_v2(getDBPath(), &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            logDebug("Successfully opened connection to database at \(getDBPath())")
            return db
        } else {
            logError("Unable to open database.")
            return nil
        }
    }

    static func getTimeStamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }

    static func getUniqueId() -> String {
        return NSUUID().uuidString.lowercased()
    }

    static func getLocale() -> String {
        let locale = Locale.current
        if #available(iOS 10.0, *) {
            return String(format: "%@-%@", locale.languageCode!, locale.regionCode!)
        }
        return "NA"
    }

    static func userAgent() -> String? {
        return WKWebView().value(forKey: "userAgent") as? String
    }
    
    static func createTraits() -> [String: Any] {
        let traits: RSTraits = RSTraits()
        traits.anonymousId = UserDefaults.standard.anonymousId
        return traits.dictionary()
    }
    
    static func getJSON(from message: RSDBMessage) -> String {
        let sentAt = RSUtils.getTimeStamp()
        logDebug("RecordCount: \(message.messages.count)")
        logDebug("sentAtTimeStamp: \(sentAt)")
        var jsonString = "{\"sentAt\":\"\(sentAt)\",\"batch\":["
        var totalBatchSize = jsonString.getUTF8Length() + 2
        var index = 0
        for message in message.messages {
            var string = message[0..<message.count - 1]
            string += ",\"sentAt\":\"\(sentAt)\"},"
            totalBatchSize += string.getUTF8Length()
            if totalBatchSize > RSConstants.MAX_BATCH_SIZE {
                logDebug("MAX_BATCH_SIZE reached at index: \(index) | Total: \(totalBatchSize)")
                break
            }
            jsonString += string
            index += 1
        }
        if jsonString.last == "," {
            jsonString = String(jsonString.dropLast())
        }
        jsonString += "]}"
        return jsonString
    }
}
