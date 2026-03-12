# Changelog

## [1.0.0-alpha.1] - 2025-07-07

### Features

- add xcworkspace file
- add Analytics framework and AnalyticsApp iOS project
- add swift file for public functions
- add storage interface
- httpclient implementation
- rudderstackdataplane plugin implementation (#5)
- post events to dataplane implementation (#6)
- flush policy implementation (#7)
- events payload implementation (#8)
- flush event implementation (#12)
- device info plugin implementation
- add locale os screen timezone plugins implementation (#15)
- add app library plugin implementation
- add network info plugin and implementation (#17)
- update plugin and message protocols to public
- update SDK compatible with iOS 15.0 and above
- add state management base classes (#23)
- implement useridentity class
- implement business logic of state in user identity
- advertising id external plugin implementation
- identify event implementation
- alias event implementation
- reset api implementation
- integrate swiftlint and apply the rules
- allow all events to set external ids
- integrate event processing channel
- manual session implementation
- implement lifecycle tracking plugin with observable session tracking events
- shut down api implementation
- rudder option plugin implementation
- add uikit swift sample app
- implement automatic screen tracking plugin
- add objective c based sample app
- add deep link tracking implementation
- add Objective-C compatibility
- add macOS compatibility
- add watchOS compatibility
- add tvOS compatibility
- remove clearAnonymousId flag from the reset api (#71)
- add remove api
- remove setAnonymousId functionality (#75)
- implement direct update mechanism for event payload
- add setpushtokenplugin external plugin
- add remove api in ObjCAnalytics
- call the reset api when userId changes in the identify event (#77)
- add URL support to AnyCodable
- move all logger-related components to LoggerAnalytics
- expose deep-link tracking api to Objective-C
- reorganize project structure
- add Swift Package Manager support
- add Apple Privacy Manifest file to comply with App Store requirements

### Bug Fixes

- update bluetooth classes initialization logic to avoid crash
- issue with automatic session reset
- prevent triggering duplicate Application Opened events (#69)
- ensure thread safety in SwiftUI app discovery
- duplicate tracking of Application Opened event
- update temporary file storage location for test cases
- replace AsyncChannel with DispatchQueue to resolve event ordering issue
- resolve broken test cases in CountFlushPolicy test cases
- optimize zombie memory consumption
- improve integration override behavior and flush policy validation

## [1.0.0-beta.1] - 2025-09-30

### Features

- update visibility of Event subclasses to public
- implement retry logic with exponential backoff for batch API uploads
- add user agent plugin examples with dynamic and static implementations
- Implement SourceConfig logic for successful server responses
- implement overloaded reset method with selective data clearing options
- implement overloaded reset method with selective data clearing options (#143)
- implement event batching based on anonymousId with automatic rollover (#144)
- implement sourceconfig logic when response is unsuccessful (#147)
- update network header based on the updated anonymousId (#149)
- implement source configuration disabling for 404 error (#150)
- add build version query parameter for source config requests (#151)
- add writeKey query param for sourceConfig request

### Bug Fixes

- allow zero milliseconds for session timeout in Objective-C configuration (#113)
- resolve shutdown implementation issues
- enhanced MockHelper to search multiple bundles
- resolve failing test cases (#154)
- resolve the optional unwrapping value (#155)

## [1.0.0] - 2025-12-16

### Features

- add iOS app extension example with Swift SDK integration (#160)
- add integration plugin protocol (#159)
- add IntegrationsController and update IntegrationsManagementPlugin implementation (#162)
- add IntegrationOptionsPlugin (#165)
- add event filtering plugin (#163)
- add E-commerce helpers and public StandardIntegration protocol (#176)
- add Objective-C compatibility layer for device mode integrations (#182)

### Bug Fixes

- handle Date, URL, and NSNull types in analytics events (#190)

## [1.0.1] - 2025-12-23

### Bug Fixes

- ensure lifecycle observer registration for existing automatic sessions (#193)

## [1.1.0] - 2026-02-17

### Features

- add persistence migration utility for legacy V1 SDK compatibility (#194)
- add persistence migration utility for legacy V2 SDK compatibility (#198)
- update event filtering plugin (#201)

### Bug Fixes

- remove nil-coalescing fallback in ObjCPluginAdapter intercept method (#202)
- refactor test classes to use mock implementations (#203)
- add missing analytics propagation to ObjC integration plugins (#204)

## [1.2.0] - 2026-03-03

### Features

- add dedicated timeout error handling and improve SSL error categorization (#205)
- add retry headers for event batch upload requests (#208)
- use system time in session management (#213)

### Bug Fixes

- ensure EventUploader stops processing when upload channel is closed (#212)
- resolve CI-specific test case failures (#211)
- ensure consistent session ID on foreground after timeout (#214)

## [1.2.1] - 2026-03-10

### Bug Fixes

- resolve data race crash in network monitor during network path changes (#217)


