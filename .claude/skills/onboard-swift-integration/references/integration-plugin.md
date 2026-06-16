# IntegrationPlugin & StandardIntegration Protocol Reference

## Protocol Hierarchy

```
Plugin
  └─ EventPlugin
       └─ IntegrationPlugin (abstract)
            └─ StandardIntegration (protocol)
```

## IntegrationPlugin (from RudderStackAnalytics)

```swift
public protocol IntegrationPlugin: EventPlugin {
    var key: String { get set }
    func create(destinationConfig: [String: Any]) throws
    func update(destinationConfig: [String: Any]) throws  // optional, default no-op
    func getDestinationInstance() -> Any?
}
```

### Key Properties & Methods

| Member | Required | Notes |
|---|---|---|
| `key: String` | Yes | Must match the exact destination name from the RudderStack dashboard |
| `pluginType: PluginType` | Yes (from Plugin) | Always set to `.terminal` for integrations |
| `analytics: Analytics?` | Yes (from Plugin) | Set automatically by the SDK when the plugin is added |
| `create(destinationConfig:)` | Yes | Called once after SourceConfig fetch. Initialize the destination SDK here. May `throw`. |
| `update(destinationConfig:)` | Optional | Called on subsequent SourceConfig fetches. Default implementation is no-op. |
| `getDestinationInstance()` | Yes | Return the destination SDK instance, or `nil` if not initialized. |

### Important: `setup()` is OFF-LIMITS

`setup()` is defined in `Plugin` and **overridden as final** in `IntegrationPlugin`. All initialization must go in `create(destinationConfig:)`, not `setup()`.

Similarly, `intercept()` is not available — do not override it.

## StandardIntegration Protocol

```swift
public protocol StandardIntegration {
    // No additional requirements — it's a marker protocol
    // that enables automatic event routing from the SDK
}
```

Conforming to `StandardIntegration` tells the SDK to route events (identify, track, screen, etc.) to this plugin's event methods automatically.

## EventPlugin Methods (inherited)

These are optional — only implement the ones the ObjC integration handles in its `dump:` method:

```swift
func identify(payload: IdentifyEvent)
func track(payload: TrackEvent)
func screen(payload: ScreenEvent)
func group(payload: GroupEvent)
func alias(payload: AliasEvent)
```

Additional optional methods:
```swift
func reset()      // Clear user state
func flush()      // Force-flush queued data
func teardown()   // Cleanup — always call super.teardown() if overriding
```

## Integration Class Template

```swift
import Foundation
import <ThirdPartySDK>
import RudderStackAnalytics

public class <Name>Integration: IntegrationPlugin, StandardIntegration {

    final let adapter: <Name>Adapter

    init(adapter: <Name>Adapter) {
        self.adapter = adapter
    }

    public convenience init() {
        self.init(adapter: Default<Name>Adapter())
    }

    public var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    public var key: String = "<ExactDashboardName>"

    public func create(destinationConfig: [String: Any]) throws {
        // Parse config, initialize destination SDK via adapter
    }

    public func getDestinationInstance() -> Any? {
        return adapter.getDestinationInstance()
    }

    // Event methods...
}
```

## ObjC Bridge Template

The ObjC bridge wraps the Swift integration for Objective-C consumers:

```swift
import Foundation
import RudderStackAnalytics

@objc(RSS<Name>Integration)
public class ObjC<Name>Integration: NSObject, ObjCIntegrationPlugin, ObjCStandardIntegration {

    public var pluginType: PluginType {
        get { integration.pluginType }
        set { integration.pluginType = newValue }
    }

    public var key: String {
        get { integration.key }
        set { integration.key = newValue }
    }

    private let integration: <Name>Integration

    @objc
    public override init() {
        self.integration = <Name>Integration()
        super.init()
    }

    @objc
    public func getDestinationInstance() -> Any? {
        return integration.getDestinationInstance()
    }

    @objc
    public func createWithDestinationConfig(
        _ destinationConfig: [String: Any],
        error errorPointer: NSErrorPointer
    ) -> Bool {
        do {
            try integration.create(destinationConfig: destinationConfig)
            return true
        } catch let err as NSError {
            errorPointer?.pointee = err
            return false
        } catch {
            errorPointer?.pointee = NSError(
                domain: "com.rudderstack.<Name>Integration",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
            return false
        }
    }
}
```

### ObjC Event Method Bridge Patterns

For each event type the integration supports, add the corresponding bridge method:

**Identify:**
```swift
@objc
public func identify(_ payload: ObjCIdentifyEvent) {
    var event = IdentifyEvent(options: payload.options)
    event.anonymousId = payload.anonymousId
    event.userId = payload.userId
    event.context = payload.context?.codableWrapped
    integration.identify(payload: event)
}
```

**Track:**
```swift
@objc
public func track(_ payload: ObjCTrackEvent) {
    var event = TrackEvent(
        event: payload.eventName,
        properties: payload.properties,
        options: payload.options
    )
    event.anonymousId = payload.anonymousId
    event.userId = payload.userId
    integration.track(payload: event)
}
```

**Screen:**
```swift
@objc
public func screen(_ payload: ObjCScreenEvent) {
    var event = ScreenEvent(
        screenName: payload.screenName,
        category: payload.category,
        properties: payload.properties,
        options: payload.options
    )
    event.anonymousId = payload.anonymousId
    event.userId = payload.userId
    integration.screen(payload: event)
}
```

**Group:**
```swift
@objc
public func group(_ payload: ObjCGroupEvent) {
    var event = GroupEvent(
        groupId: payload.groupId,
        traits: payload.traits,
        options: payload.options
    )
    event.anonymousId = payload.anonymousId
    event.userId = payload.userId
    integration.group(payload: event)
}
```

**Alias:**
```swift
@objc
public func alias(_ payload: ObjCAliasEvent) {
    var event = AliasEvent(
        newId: payload.newId,
        previousId: payload.previousId,
        options: payload.options
    )
    event.anonymousId = payload.anonymousId
    event.userId = payload.userId
    integration.alias(payload: event)
}
```

**Reset / Flush:**
```swift
@objc
public func reset() {
    integration.reset()
}

@objc
public func flush() {
    integration.flush()
}
```

Only include bridge methods for events the Swift integration actually implements.
