//
//  AppTestingHelper.swift
//  AnalyticsAppTests
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Foundation
import Analytics

// MARK: - MockEvent
class MockEvent: Message {
    var anonymousId: String?
    var channel: String?
    var integrations: [String : Bool]?
    var sentAt: String?
    var context: [String : Analytics.AnyCodable]?
    var traits: Analytics.CodableCollection?
    var type: Analytics.EventType = .track
    var messageId: String = UUID().uuidString
    var originalTimeStamp: String = Date().description
}


// MARK: - Given_When_Then
func given(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("Given \(description)") }
    closure()
}

func when(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("When \(description)") }
    closure()
}

func then(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("Then \(description)") }
    closure()
}

