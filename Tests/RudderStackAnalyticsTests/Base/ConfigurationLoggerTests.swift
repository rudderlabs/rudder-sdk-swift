//
//  ConfigurationLoggerTests.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 02/06/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("Configuration Logger Wiring Tests")
struct ConfigurationLoggerTests {

    private func makeConfiguration(logger: Logger? = nil, logLevel: LogLevel? = nil) -> Configuration {
        if let logLevel {
            return Configuration(writeKey: MockConstant.mockWriteKey, dataPlaneUrl: MockConstant.mockDataPlaneUrl, logger: logger, logLevel: logLevel)
        }
        return Configuration(writeKey: MockConstant.mockWriteKey, dataPlaneUrl: MockConstant.mockDataPlaneUrl, logger: logger)
    }

    @Test("given no logger, when a Configuration is created, then logger is wrapped in a level-aware AnalyticsLogger")
    func testDefaultLoggerIsWrapped() {
        let config = makeConfiguration()
        #expect(config.logger is AnalyticsLogger)
    }

    @Test("given only a logLevel and no custom logger, when a Configuration is created, then the default logger is wrapped in an AnalyticsLogger carrying that level",
          arguments: [LogLevel.none, .error, .warn, .info, .debug, .verbose])
    func testOnlyLogLevelSetUsesWrappedDefaultLogger(level: LogLevel) {
        // No `logger:` argument — the SDK should fall back to its default sink,
        // still wrapped so the level is honoured. The overwrite bug replaced this
        // wrapper with a raw, unfiltered logger.
        let config = makeConfiguration(logLevel: level)
        #expect(config.logger is AnalyticsLogger)
        #expect(config.logLevel == level)
    }

    @Test("given a custom logger, when a Configuration is created, then logger is still wrapped in AnalyticsLogger and not the raw logger")
    func testCustomLoggerIsWrapped() {
        let mockLogger = MockLogger()
        let config = makeConfiguration(logger: mockLogger)
        #expect(config.logger is AnalyticsLogger)
        #expect(!(config.logger is MockLogger))
    }

    @Test("given logLevel none, when logging through Configuration.logger, then nothing is captured")
    func testNoneLevelSuppressesAllLogs() {
        let mockLogger = MockLogger()
        let config = makeConfiguration(logger: mockLogger, logLevel: LogLevel.none)

        config.logger.verbose(log: "verbose")
        config.logger.debug(log: "debug")
        config.logger.info(log: "info")
        config.logger.warn(log: "warn")
        config.logger.error(log: "error", error: nil)

        #expect(mockLogger.logs.isEmpty)
    }

    @Test("given logLevel verbose, when logging through Configuration.logger, then every level is captured")
    func testVerboseLevelLogsEverything() {
        let mockLogger = MockLogger()
        let config = makeConfiguration(logger: mockLogger, logLevel: .verbose)

        config.logger.verbose(log: "verbose")
        config.logger.debug(log: "debug")
        config.logger.info(log: "info")
        config.logger.warn(log: "warn")
        config.logger.error(log: "error", error: nil)

        let levels = mockLogger.logs.map { $0.level }
        #expect(levels.contains("VERBOSE"))
        #expect(levels.contains("DEBUG"))
        #expect(levels.contains("INFO"))
        #expect(levels.contains("WARN"))
        #expect(levels.contains("ERROR"))
    }

    @Test("given an omitted logLevel, when a Configuration is created, then it defaults to none and suppresses logs")
    func testDefaultLogLevelIsNone() {
        let mockLogger = MockLogger()
        let config = makeConfiguration(logger: mockLogger)

        #expect(config.logLevel == .none)

        config.logger.verbose(log: "verbose")
        config.logger.error(log: "error", error: nil)

        #expect(mockLogger.logs.isEmpty)
    }

    @Test("given logLevel warn, when logging through Configuration.logger, then only warn and error are captured")
    func testWarnLevelFiltersLowerSeverity() {
        let mockLogger = MockLogger()
        let config = makeConfiguration(logger: mockLogger, logLevel: .warn)

        config.logger.verbose(log: "verbose")
        config.logger.debug(log: "debug")
        config.logger.info(log: "info")
        config.logger.warn(log: "warn")
        config.logger.error(log: "error", error: nil)

        let levels = mockLogger.logs.map { $0.level }
        #expect(!levels.contains("VERBOSE"))
        #expect(!levels.contains("DEBUG"))
        #expect(!levels.contains("INFO"))
        #expect(levels.contains("WARN"))
        #expect(levels.contains("ERROR"))
    }
}
