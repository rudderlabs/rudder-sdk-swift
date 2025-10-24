//
//  SourceConfigTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 24/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("SourceConfig Tests")
struct SourceConfigTests {
        
    @Test("when creating SourceConfig initialState, then returns valid default configuration")
    func testSourceConfig_InitialState() {
        let sourceConfig = SourceConfig.initialState()
        
        #expect(sourceConfig.source.sourceId.isEmpty)
        #expect(sourceConfig.source.sourceName.isEmpty)
        #expect(sourceConfig.source.writeKey.isEmpty)
        #expect(sourceConfig.source.isSourceEnabled == true)
        #expect(sourceConfig.source.workspaceId.isEmpty)
        #expect(sourceConfig.source.updatedAt.isEmpty)
        #expect(sourceConfig.source.destinations.isEmpty)
        #expect(sourceConfig.source.metricConfig.statsCollection.errors.enabled == false)
        #expect(sourceConfig.source.metricConfig.statsCollection.metrics.enabled == false)
    }
    
    @Test("when encoding SourceConfig to JSON, then produces valid JSON structure")
    func testSourceConfig_JSONEncoding() throws {
        let destination = Destination(
            destinationId: "dest-123",
            destinationName: "Test Destination",
            isDestinationEnabled: true,
            destinationConfig: ["key": AnyCodable("value")],
            destinationDefinitionId: "def-123",
            destinationDefinition: DestinationDefinition(
                name: "test-destination",
                displayName: "Test Destination"
            ),
            updatedAt: "2023-10-24T10:00:00Z",
            shouldApplyDeviceModeTransformation: false,
            propagateEventsUntransformedOnError: true
        )
        
        let sourceConfig = SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "source-123",
                sourceName: "Test Source",
                writeKey: "test-write-key",
                isSourceEnabled: true,
                workspaceId: "workspace-123",
                updatedAt: "2023-10-24T10:00:00Z",
                metricConfig: MetricsConfig(),
                destinations: [destination]
            )
        )
        
        let jsonObject = sourceConfig.dictionary ?? [String: Any]()
        
        guard let source = jsonObject["source"] as? [String: Any] else {
            Issue.record("Can't read source details")
            return
        }
        #expect(source["id"] as? String == "source-123")
        #expect(source["name"] as? String == "Test Source")
        #expect(source["writeKey"] as? String == "test-write-key")
        #expect(source["enabled"] as? Bool == true)
        #expect(source["workspaceId"] as? String == "workspace-123")
        #expect(source["updatedAt"] as? String == "2023-10-24T10:00:00Z")
        
        guard let destinations = source["destinations"] as? [[String: Any]] else {
            Issue.record("Can't read destinations details")
            return
        }
        #expect(destinations.count == 1)
        #expect(destinations.first?["id"] as? String == "dest-123")
    }
    
    @Test("when decoding SourceConfig from JSON, then creates valid SourceConfig object")
    func testSourceConfig_JSONDecoding() throws {
        let jsonString = """
        {
            "source": {
                "id": "source-456",
                "name": "Decoded Source",
                "writeKey": "decoded-write-key",
                "enabled": false,
                "workspaceId": "workspace-456",
                "updatedAt": "2023-10-24T11:00:00Z",
                "config": {
                    "statsCollection": {
                        "errors": {
                            "enabled": true
                        },
                        "metrics": {
                            "enabled": true
                        }
                    }
                },
                "destinations": []
            }
        }
        """
        
        let jsonData = jsonString.utf8Data ?? Data()
        let sourceConfig = try JSONDecoder().decode(SourceConfig.self, from: jsonData)
        
        #expect(sourceConfig.source.sourceId == "source-456")
        #expect(sourceConfig.source.sourceName == "Decoded Source")
        #expect(sourceConfig.source.writeKey == "decoded-write-key")
        #expect(sourceConfig.source.isSourceEnabled == false)
        #expect(sourceConfig.source.workspaceId == "workspace-456")
        #expect(sourceConfig.source.updatedAt == "2023-10-24T11:00:00Z")
        #expect(sourceConfig.source.metricConfig.statsCollection.errors.enabled == true)
        #expect(sourceConfig.source.metricConfig.statsCollection.metrics.enabled == true)
        #expect(sourceConfig.source.destinations.isEmpty)
    }
    
    @Test("when creating MetricsConfig with default values, then has correct default settings")
    func testMetricsConfig_DefaultValues() {
        let metricsConfig = MetricsConfig()
        
        #expect(metricsConfig.statsCollection.errors.enabled == false)
        #expect(metricsConfig.statsCollection.metrics.enabled == false)
    }
    
    @Test("when creating Destination with all properties, then all properties are correctly set")
    func testDestination_AllProperties() {
        let destinationDefinition = DestinationDefinition(
            name: "amplitude",
            displayName: "Amplitude"
        )
        
        let destinationConfig = [
            "apiKey": AnyCodable("test-api-key"),
            "trackUtmProperties": AnyCodable(true),
            "batchEvents": AnyCodable(false)
        ]
        
        let destination = Destination(
            destinationId: "dest-789",
            destinationName: "Amplitude Destination",
            isDestinationEnabled: true,
            destinationConfig: destinationConfig,
            destinationDefinitionId: "def-789",
            destinationDefinition: destinationDefinition,
            updatedAt: "2023-10-24T12:00:00Z",
            shouldApplyDeviceModeTransformation: true,
            propagateEventsUntransformedOnError: false
        )
        
        #expect(destination.destinationId == "dest-789")
        #expect(destination.destinationName == "Amplitude Destination")
        #expect(destination.isDestinationEnabled == true)
        #expect(destination.destinationConfig.count == 3)
        #expect(destination.destinationConfig["apiKey"]?.value as? String == "test-api-key")
        #expect(destination.destinationConfig["trackUtmProperties"]?.value as? Bool == true)
        #expect(destination.destinationConfig["batchEvents"]?.value as? Bool == false)
        #expect(destination.destinationDefinitionId == "def-789")
        #expect(destination.destinationDefinition.name == "amplitude")
        #expect(destination.destinationDefinition.displayName == "Amplitude")
        #expect(destination.updatedAt == "2023-10-24T12:00:00Z")
        #expect(destination.shouldApplyDeviceModeTransformation == true)
        #expect(destination.propagateEventsUntransformedOnError == false)
    }
}
