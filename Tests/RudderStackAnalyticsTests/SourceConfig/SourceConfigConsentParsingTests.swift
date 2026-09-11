//
//  SourceConfigConsentParsingTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("SourceConfig Consent Parsing Tests")
struct SourceConfigConsentParsingTests {
    // MARK: - Decoding

    @Test("given metadata at the response root, when decoding, then providers round-trip")
    func testMetadataDecodedFromRoot() throws {
        let json = makeResponseJson(metadataFragment: """
        { "providers": [
            { "provider": "oneTrust", "resolutionStrategy": "and" },
            { "provider": "ketch", "resolutionStrategy": "or" }
        ] }
        """)

        let sourceConfig = try decodeSourceConfig(from: json)

        let providers = sourceConfig.consentManagementMetadata?.providers
        #expect(providers?.count == 2)
        #expect(providers?.first?.provider == "oneTrust")
        #expect(providers?.first?.resolutionStrategy == "and")
        #expect(providers?.last?.provider == "ketch")
        #expect(providers?.last?.resolutionStrategy == "or")
    }

    @Test("given no consentManagementMetadata key, when decoding, then the field is nil")
    func testAbsentMetadataKeyDecodesToNil() throws {
        let sourceConfig = try decodeSourceConfig(from: makeResponseJson())

        #expect(sourceConfig.consentManagementMetadata == nil)
    }

    @Test("given a named-provider entry with an empty resolutionStrategy, when decoding, then it parses cleanly")
    func testEmptyStrategyOnNamedProviderParses() throws {
        let json = makeResponseJson(metadataFragment: """
        { "providers": [ { "provider": "ketch", "resolutionStrategy": "" } ] }
        """)

        let sourceConfig = try decodeSourceConfig(from: json)

        #expect(sourceConfig.consentManagementMetadata?.providers.first?.resolutionStrategy?.isEmpty == true)
    }

    @Test("given unknown providers, strategies, and extra fields, when decoding, then parsing tolerates them")
    func testUnknownValuesAreTolerated() throws {
        let json = makeResponseJson(metadataFragment: """
        { "providers": [
            { "provider": "someFutureProvider", "resolutionStrategy": "banana", "futureField": 42 }
        ], "futureBlock": { "nested": true } }
        """)

        let sourceConfig = try decodeSourceConfig(from: json)

        #expect(sourceConfig.consentManagementMetadata?.providers.first?.provider == "someFutureProvider")
        #expect(sourceConfig.consentManagementMetadata?.providers.first?.resolutionStrategy == "banana")
    }

    @Test("given malformed metadata blobs, when decoding, then the field degrades to nil without failing the parse", arguments: [
        "\"garbage-string\"",
        "42",
        "{ \"providers\": \"not-an-array\" }",
        "{ \"providers\": [ { \"provider\": 42 } ] }",
        "[]"
    ])
    func testMalformedMetadataDegradesToNil(_ metadataFragment: String) throws {
        let sourceConfig = try decodeSourceConfig(from: makeResponseJson(metadataFragment: metadataFragment))

        #expect(sourceConfig.consentManagementMetadata == nil, "A malformed metadata blob must never fail source-config parsing — it degrades to nil (ungated).")
        #expect(sourceConfig.source.sourceId == "source-id", "The rest of the source config must decode normally.")
    }

    // MARK: - Model defaults

    @Test("given the initial state, when created, then the metadata is nil")
    func testInitialStateHasNilMetadata() {
        #expect(SourceConfig.initialState().consentManagementMetadata == nil)
    }

    @Test("given a config with metadata, when encoded, then the metadata survives the round-trip")
    func testEncodingRoundTrip() throws {
        let original = SourceConfig(
            source: SourceConfig.initialState().source,
            consentManagementMetadata: ConsentManagementMetadata(providers: [
                ConsentProviderEntry(provider: "oneTrust", resolutionStrategy: "and")
            ])
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SourceConfig.self, from: encoded)

        #expect(decoded.consentManagementMetadata == original.consentManagementMetadata, "Storage round-trips must preserve the metadata.")
    }

    // MARK: - DisableSourceConfigAction regression

    @Test("given a config with metadata, when the disable action rebuilds it, then the metadata survives")
    func testDisableActionPreservesMetadata() throws {
        let json = makeResponseJson(metadataFragment: """
        { "providers": [ { "provider": "oneTrust", "resolutionStrategy": "and" } ] }
        """)
        let original = try decodeSourceConfig(from: json)
        #expect(original.consentManagementMetadata != nil, "Precondition: the fixture must carry metadata.")

        let result = DisableSourceConfigAction().reduce(currentState: original)

        #expect(result.source.isSourceEnabled == false)
        #expect(result.consentManagementMetadata == original.consentManagementMetadata, "Regression: the field-by-field rebuild silently drops unthreaded fields — this proves consentManagementMetadata is threaded.")
    }
}

// MARK: - Helpers
extension SourceConfigConsentParsingTests {
    /**
     Builds a minimal valid source-config response, optionally injecting a raw
     `consentManagementMetadata` JSON fragment at the response root.
     */
    private func makeResponseJson(metadataFragment: String? = nil) -> String {
        let metadata = metadataFragment.map { ", \"consentManagementMetadata\": \($0)" } ?? ""
        return """
        {
          "source": {
            "id": "source-id",
            "name": "source-name",
            "writeKey": "write-key",
            "enabled": true,
            "workspaceId": "workspace-id",
            "updatedAt": "2026-01-01T00:00:00.000Z",
            "config": { "statsCollection": { "errors": { "enabled": false }, "metrics": { "enabled": false } } },
            "destinations": []
          }\(metadata)
        }
        """
    }

    private func decodeSourceConfig(from json: String) throws -> SourceConfig {
        try JSONDecoder().decode(SourceConfig.self, from: Data(json.utf8))
    }
}
