//
//  RSDatabaseManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 10/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation
import SQLite3

class RSDatabaseManager {
    
    let database: OpaquePointer?
    
    init() {
        database = RSUtils.openDatabase()
        createTable()
    }
    
    func createTable() {
        var createTableStatement: OpaquePointer?
        let createTableString = "CREATE TABLE IF NOT EXISTS events( id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT NOT NULL, updated INTEGER NOT NULL);"
        logDebug("createTableSQL: \(createTableString)")
        if sqlite3_prepare_v2(database, createTableString, -1, &createTableStatement, nil) ==
            SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                logDebug("DB Schema created")
            } else {
                logError("DB Schema creation error")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logError("DB Schema CREATE statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func saveEvent(_ message: String) {
        let insertStatementString = "INSERT INTO events (message, updated) VALUES (?, ?);"
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(database, insertStatementString, -1, &insertStatement, nil) ==
            SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, ((message.replacingOccurrences(of: "'", with: "''")) as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 2, Int32(RSUtils.getTimeStamp()))
            logDebug("saveEventSQL: \(insertStatementString)")
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                logDebug("Event inserted to table")
            } else {
                logError("Event insertion error")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logError("Event INSERT statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func clearEvents(_ messageIds: [String]) {
        var deleteStatement: OpaquePointer?
        let deleteStatementString = "DELETE FROM events WHERE id IN (\((messageIds as NSArray).componentsJoined(by: ",") as NSString));"
        logDebug("deleteEventSQL: \(deleteStatementString)")
        if sqlite3_prepare_v2(database, deleteStatementString, -1, &deleteStatement, nil) ==
            SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                logDebug("Events deleted from DB")
            } else {
                logError("Event deletion error")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logError("Event DELETE statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func fetchEvents(_ count: Int) -> RSDBMessage? {
        var queryStatement: OpaquePointer?
        var message: RSDBMessage?
        let queryStatementString = "SELECT * FROM events ORDER BY updated ASC LIMIT \(count);"
        logDebug("countSQL: \(queryStatementString)")
        if sqlite3_prepare_v2(database, queryStatementString, -1, &queryStatement, nil) ==
            SQLITE_OK {
            var messages = [String]()
            var messageIds = [String]()
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let messageId = "\(Int(sqlite3_column_int(queryStatement, 0)))"
                guard let message = sqlite3_column_text(queryStatement, 1) else {
                    continue
                }
                messageIds.append(messageId)
                messages.append(String(cString: message))
            }
            message = RSDBMessage(messages: messages, messageIds: messageIds)
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logError("Event SELECT statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(queryStatement)
        return message
    }
    
    func getDBRecordCount() -> Int {
        var queryStatement: OpaquePointer?
        let queryStatementString = "SELECT COUNT(*) FROM 'events'"
        logDebug("countSQL: \(queryStatementString)")
        var count = 0
        if sqlite3_prepare_v2(database, queryStatementString, -1, &queryStatement, nil) ==
            SQLITE_OK {
            logDebug("count fetched from DB")
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logError("count SELECT statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(queryStatement)
        return count
    }
    
    func clearAllEvents() {
        var deleteStatement: OpaquePointer?
        let deleteStatementString = "DELETE FROM 'events';"
        if sqlite3_prepare_v2(database, deleteStatementString, -1, &deleteStatement, nil) ==
            SQLITE_OK {
            logDebug("deleteEventSQL: \(deleteStatementString)")
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                logDebug("Events deleted from DB")
            } else {
                logError("Event deletion error")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logError("Event DELETE statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(deleteStatement)
    }
}
