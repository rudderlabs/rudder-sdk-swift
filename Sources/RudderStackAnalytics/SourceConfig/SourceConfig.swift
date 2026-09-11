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
struct SourceConfig: Codable, Equatable {
    let source: RudderServerConfigSource
    let consentManagementMetadata: ConsentManagementMetadata?
    
    init(source: RudderServerConfigSource, consentManagementMetadata: ConsentManagementMetadata? = nil) {
        self.source = source
        self.consentManagementMetadata = consentManagementMetadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try container.decode(RudderServerConfigSource.self, forKey: .source)
        self.consentManagementMetadata = try? container.decodeIfPresent(ConsentManagementMetadata.self, forKey: .consentManagementMetadata)
    }
    
    /**
     Creates an initial state of the source configuration.
     */
    static func initialState() -> SourceConfig {
        return SourceConfig(
            source: RudderServerConfigSource(
                sourceId: .empty,
                sourceName: .empty,
                writeKey: .empty,
                isSourceEnabled: true,
                workspaceId: .empty,
                updatedAt: .empty,
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
struct RudderServerConfigSource: Codable, Equatable {
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

// MARK: - ConsentManagementMetadata
/**
 Workspace-level consent provider metadata, decoded from the source config response root — a sibling of `source` on the wire, not part of `source.config`.
 */
struct ConsentManagementMetadata: Codable, Equatable {
    let providers: [ConsentProviderEntry]
}

// MARK: - ConsentProviderEntry
/**
 A single provider entry. Fields are optional and free-form so unknown providers, strategies, or extra fields never fail parsing; an empty `resolutionStrategy` on named-provider entries is tolerated and resolved downstream.
 */
struct ConsentProviderEntry: Codable, Equatable {
    let provider: String?
    let resolutionStrategy: String?
}

// MARK: - MetricsConfig
/**
 Represents the configuration for metrics collection.
 */
struct MetricsConfig: Codable, Equatable {
    let statsCollection: StatsCollection
    
    init() {
        self.statsCollection = StatsCollection()
    }
}

// MARK: - StatsCollection
/**
 Represents the configuration for statistics collection.
 */
struct StatsCollection: Codable, Equatable {
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
struct Errors: Codable, Equatable {
    let enabled: Bool
    
    init(enabled: Bool = false) {
        self.enabled = enabled
    }
}

struct Metrics: Codable, Equatable {
    let enabled: Bool
    
    init(enabled: Bool = false) {
        self.enabled = enabled
    }
}

// MARK: - Destination
/**
 Represents the configuration of a destination in RudderStack.
 */
struct Destination: Codable, Equatable {
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
struct DestinationDefinition: Codable, Equatable {
    let name: String
    let displayName: String
}
