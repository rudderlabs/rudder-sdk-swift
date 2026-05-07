//
//  PackRegistry.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

class PackRegistry {

    // MARK: - Properties

    static let shared = PackRegistry()
    private var packs: [String: [Step]] = [:]

    private init() {}
}

// MARK: - Registration

extension PackRegistry {

    func register(name: String, steps: [Step]) {
        packs[name] = steps
    }

    func list(filter: String?) -> [[String: String]] {
        packs.keys
            .filter { filter == nil || $0.contains(filter!) }
            .sorted()
            .map { ["name": $0] }
    }

    func load(name: String) throws -> [Step] {
        guard let steps = packs[name] else {
            throw ScenarioError.assertionFailed("Unknown scenario pack: '\(name)'")
        }
        return steps
    }
}
