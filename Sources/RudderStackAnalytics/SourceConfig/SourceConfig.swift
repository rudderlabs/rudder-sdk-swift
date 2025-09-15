//
//  SourceConfig.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 15/09/25.
//

import Foundation

// MARK: - SourceConfig
/**
 Represents the configuration for a source in the RudderStack server.
 */
struct SourceConfig: Codable {
    let source: RudderServerConfigSource
    
    /**
     Creates an initial state of the source configuration.
     */
    static func initialState() -> SourceConfig {
        return SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "",
                sourceName: "",
                writeKey: "",
                isSourceEnabled: true,
                workspaceId: "",
                updatedAt: "",
                metricConfig: MetricsConfig(),
                destinations: []
            )
        )
    }
}

// MARK: - RudderServerConfigSource
/**
 Represents the configuration of a source from the RudderStack server.
 */
struct RudderServerConfigSource: Codable {
    let sourceId: String
    let sourceName: String
    let writeKey: String
    let isSourceEnabled: Bool
    let workspaceId: String
    let updatedAt: String
    let metricConfig: MetricsConfig
    let destinations: [Destination]
    
    enum CodingKeys: String, CodingKey {
        case sourceId = "id"
        case sourceName = "name"
        case writeKey
        case isSourceEnabled = "enabled"
        case workspaceId
        case updatedAt
        case metricConfig = "config"
        case destinations
    }
}

// MARK: - MetricsConfig
/**
 Represents the configuration for metrics collection.
 */
struct MetricsConfig: Codable {
    let statsCollection: StatsCollection
    
    init() {
        self.statsCollection = StatsCollection()
    }
}

// MARK: - StatsCollection
/**
 Represents the configuration for statistics collection.
 */
struct StatsCollection: Codable {
    let errors: Errors
    let metrics: Metrics
    
    init() {
        self.errors = Errors()
        self.metrics = Metrics()
    }
}

// MARK: - Errors & Metrics
/**
 Configuration for error and metrics collection.
 */
struct Errors: Codable {
    let enabled: Bool
    
    init(enabled: Bool = false) {
        self.enabled = enabled
    }
}

struct Metrics: Codable {
    let enabled: Bool
    
    init(enabled: Bool = false) {
        self.enabled = enabled
    }
}

// MARK: - Destination
/**
 Represents the configuration of a destination in RudderStack.
 */
struct Destination: Codable {
    let destinationId: String
    let destinationName: String
    let isDestinationEnabled: Bool
    let destinationConfig: [String: AnyCodable]
    let destinationDefinitionId: String
    let destinationDefinition: DestinationDefinition
    let updatedAt: String
    let shouldApplyDeviceModeTransformation: Bool
    let propagateEventsUntransformedOnError: Bool
    
    private enum CodingKeys: String, CodingKey {
        case destinationId = "id"
        case destinationName = "name"
        case isDestinationEnabled = "enabled"
        case destinationConfig = "config"
        case destinationDefinitionId
        case destinationDefinition
        case updatedAt
        case shouldApplyDeviceModeTransformation
        case propagateEventsUntransformedOnError
    }
}

// MARK: - DestinationDefinition
/**
 Represents the definition of a destination in RudderStack.
 */
struct DestinationDefinition: Codable {
    let name: String
    let displayName: String
}
