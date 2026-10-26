//
//  GzipTests.swift
//  RudderStackAnalyticsTests
//
//  Tests for the Data gzip helpers: gzipped(), gunzipped() and isGzipped.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - Gzip Tests

@Suite("Gzip Tests")
struct GzipTests {

    // MARK: - Empty input

    @Test("given empty data, when gzipping, then returns empty data")
    func testGzipEmptyData() throws {
        #expect(try Data().gzipped().isEmpty)
    }

    @Test("given empty data, when gunzipping, then returns empty data")
    func testGunzipEmptyData() throws {
        #expect(try Data().gunzipped().isEmpty)
    }

    // MARK: - Round trip

    @Test("given an event batch, when gzipping, then output is gzip data that gunzips back to the original")
    func testGzipRoundTripEventBatch() throws {
        let original = Data("{\"batch\":[{\"event\":\"Test\",\"properties\":{\"key\":\"value\"}}]}".utf8)

        let compressed = try original.gzipped()

        #expect(compressed.isGzipped)
        #expect(compressed != original)
        #expect(try compressed.gunzipped() == original)
    }

    @Test(
        "given incompressible data around the 16 KB output chunk size, when round-tripping, then data is preserved",
        arguments: [1, 16 * 1024 - 1, 16 * 1024, 16 * 1024 + 1, 50_000, 200_000]
    )
    func testGzipRoundTripAcrossOutputChunkBoundaries(size: Int) throws {
        // Random bytes don't compress, so the output exceeds the input and forces the output buffer to grow.
        let original = Self.pseudoRandomData(count: size)

        let compressed = try original.gzipped()

        #expect(compressed.isGzipped)
        #expect(compressed.count > 16 * 1024 || size < 16 * 1024)
        #expect(try compressed.gunzipped() == original)
    }

    @Test("given highly compressible data, when gunzipping, then output buffer grows well beyond twice the input size")
    func testGunzipGrowsBufferForHighCompressionRatio() throws {
        let original = Data(repeating: 0x61, count: 1024 * 1024)

        let compressed = try original.gzipped()

        // gunzipped() starts with 2x the compressed size, so this needs many growth iterations.
        #expect(compressed.count * 2 < original.count)
        #expect(try compressed.gunzipped() == original)
    }

    @Test(
        "given each compression level, when round-tripping, then data is preserved",
        arguments: [CompressionLevel.noCompression, .bestSpeed, .bestCompression, .defaultCompression]
    )
    func testGzipRoundTripForCompressionLevel(level: CompressionLevel) throws {
        let original = Data(String(repeating: "rudderstack-event-", count: 2_000).utf8)

        let compressed = try original.gzipped(level: level)

        #expect(compressed.isGzipped)
        #expect(try compressed.gunzipped() == original)
    }

    @Test("given compressible data, when gzipping with best compression, then output is smaller than with no compression")
    func testCompressionLevelAffectsOutputSize() throws {
        let original = Data(String(repeating: "rudderstack-event-", count: 2_000).utf8)

        let stored = try original.gzipped(level: .noCompression)
        let best = try original.gzipped(level: .bestCompression)

        #expect(stored.count > original.count)
        #expect(best.count < original.count)
    }

    // MARK: - Interoperability

    @Test("given gzip data produced by a standard gzip encoder, when gunzipping, then returns the original payload")
    func testGunzipStandardGzipFixture() throws {
        // `gzip.compress(b'{"batch":[{"event":"Test"}]}', mtime=0)` from Python's standard library.
        let fixture = Data([
            0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0xab, 0x56, 0x4a, 0x4a, 0x2c, 0x49,
            0xce, 0x50, 0xb2, 0x8a, 0xae, 0x56, 0x4a, 0x2d, 0x4b, 0xcd, 0x2b, 0x51, 0xb2, 0x52, 0x0a, 0x49,
            0x2d, 0x2e, 0x51, 0xaa, 0x8d, 0xad, 0x05, 0x00, 0x68, 0x74, 0x29, 0xb1, 0x1c, 0x00, 0x00, 0x00
        ])

        #expect(fixture.isGzipped)
        #expect(try fixture.gunzipped() == Data("{\"batch\":[{\"event\":\"Test\"}]}".utf8))
    }

    // MARK: - Error handling

    @Test("given data that is not gzip, when gunzipping, then throws GzipError")
    func testGunzipNonGzipDataThrows() {
        let plain = Data("{\"batch\":[]}".utf8)

        #expect(throws: GzipError.self) { try plain.gunzipped() }
    }

    @Test("given truncated gzip data, when gunzipping, then throws GzipError instead of returning partial data")
    func testGunzipTruncatedDataThrows() throws {
        let compressed = try Self.pseudoRandomData(count: 50_000).gzipped()
        let truncated = compressed.prefix(compressed.count / 2)

        #expect(throws: GzipError.self) { try Data(truncated).gunzipped() }
    }

    @Test("given gzip data with a corrupted checksum, when gunzipping, then throws GzipError with the zlib message")
    func testGunzipCorruptedChecksumThrows() throws {
        var compressed = try Data("{\"batch\":[{\"event\":\"Test\"}]}".utf8).gzipped()
        // The gzip trailer is CRC32 (4 bytes) followed by the input size (4 bytes).
        compressed[compressed.count - 8] ^= 0xff

        let error = #expect(throws: GzipError.self) { try compressed.gunzipped() }
        #expect(error?.message == "incorrect data check")
    }

    @Test("given an invalid window size, when gzipping, then throws GzipError")
    func testGzipInvalidWindowBitsThrows() {
        #expect(throws: GzipError.self) { try Data("payload".utf8).gzipped(wBits: 100) }
    }

    @Test("given an invalid window size, when gunzipping, then throws GzipError")
    func testGunzipInvalidWindowBitsThrows() throws {
        let compressed = try Data("payload".utf8).gzipped()

        #expect(throws: GzipError.self) { try compressed.gunzipped(wBits: 100) }
    }

    // MARK: - isGzipped

    @Test(
        "given data without the gzip magic header, when checking isGzipped, then returns false",
        arguments: [Data(), Data([0x1f]), Data([0x8b, 0x1f]), Data("{}".utf8)]
    )
    func testIsGzippedFalseWithoutMagicHeader(data: Data) {
        #expect(!data.isGzipped)
    }
}

// MARK: - Helpers

extension GzipTests {
    /// Deterministic, incompressible bytes (SplitMix64), so failures are reproducible.
    static func pseudoRandomData(count: Int) -> Data {
        var state: UInt64 = 0x9E3779B97F4A7C15
        var bytes = [UInt8]()
        bytes.reserveCapacity(count)
        while bytes.count < count {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            value ^= value >> 31
            withUnsafeBytes(of: value) { bytes.append(contentsOf: $0.prefix(count - bytes.count)) }
        }
        return Data(bytes)
    }
}
