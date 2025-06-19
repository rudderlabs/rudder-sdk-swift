//
//  AppTestingHelper.swift
//  SwiftUIAppTests
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - MockEvent
class MockEvent: Event {
    var anonymousId: String?
    var channel: String?
    var integrations: [String : AnyCodable]?
    var sentAt: String?
    var context: [String : AnyCodable]?
    var traits: CodableCollection?
    var type: EventType = .track
    var messageId: String = UUID().uuidString
    var originalTimestamp: String = Date().description
    var userId: String?
    var userIdentity: UserIdentity?
    var options: RudderOption?
    
    enum CodingKeys: String, CodingKey {
        case anonymousId
        case channel
        case integrations
        case sentAt
        case context
        case traits
        case type
        case messageId
        case originalTimestamp
        case userId
    }
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

