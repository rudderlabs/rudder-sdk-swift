//
//  Helpers.swift
//  Analytics
//
//  Created by Satheesh Kannan on 26/08/24.
//

import Foundation

public struct Constants {
    public static let logTag = "Rudder-Analytics"
    public static let defaultLogLevel = LogLevel.none
    
    private init() {}
}

extension String {
    static var randomUUIDString: String {
        return UUID().uuidString
    }
    
    static var currentTimeStamp: String {
        return String.timeStampFromDate(Date()).replacingOccurrences(of: "+00:00", with: "Z")
    }
    
    static func timeStampFromDate(_ date: Date) -> String {
        let formattedDate = DateFormatter.timeStampFormat.string(from: date)
        return formattedDate.replacingOccurrences(of: "+00:00", with: "Z")
    }
}

extension DateFormatter {
    static var timeStampFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }
}
