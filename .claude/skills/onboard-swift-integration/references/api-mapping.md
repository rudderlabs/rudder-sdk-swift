# ObjC iOS v1 → Swift SDK Method Mapping

## Method Mapping Table

| ObjC iOS v1 | Swift SDK | Notes |
|---|---|---|
| `RudderXxxFactory.instance(withXxx:)` / `initWithXxx:` | `<Name>Integration()` (convenience init) | ObjC factory pattern → Swift direct init |
| `RudderXxxIntegration.initWithConfig:client:rudderConfig:` | `create(destinationConfig: [String: Any]) throws` | Constructor logic moves to `create()`. Config is a `[String: Any]` dictionary. |
| `dump:(RudderMessage *)message` with `[message.type isEqualToString:@"identify"]` | `identify(payload: IdentifyEvent)` | ObjC single-method dispatch → Swift separate methods |
| `dump:` with `@"track"` | `track(payload: TrackEvent)` | |
| `dump:` with `@"screen"` | `screen(payload: ScreenEvent)` | |
| `dump:` with `@"group"` | `group(payload: GroupEvent)` | |
| `dump:` with `@"alias"` | `alias(payload: AliasEvent)` | |
| `reset` | `reset()` | |
| `flush` | `flush()` | |
| *(no equivalent)* | `update(destinationConfig: [String: Any]) throws` | New in Swift — implement only if the destination SDK supports runtime reconfiguration |
| *(no equivalent)* | `getDestinationInstance() -> Any?` | Required by protocol — return the destination SDK instance (or `nil` if not initialized) |
| *(no equivalent)* | `teardown()` | Available but rarely needed — always call `super.teardown()` if overriding |

## Event Payload Property Access

### ObjC (from `RudderMessage`)
```objc
message.userId
message.event
message.properties   // NSDictionary
message.traits       // NSDictionary (on identify)
message.context      // NSDictionary
```

### Swift Equivalents

| Event Type | Property | Swift Access |
|---|---|---|
| All | userId | `payload.userId` |
| All | anonymousId | `payload.anonymousId` |
| All | context | `payload.context` (as `[String: AnyCodable]?`) |
| Identify | traits | `payload.context?["traits"]` (as `AnyCodable`, then `.value as? [String: Any]`) |
| Track | event name | `payload.event` |
| Track | properties | `payload.properties?.dictionary?.rawDictionary` → `[String: Any]?` |
| Screen | screen name | `payload.event` |
| Screen | properties | `payload.properties?.dictionary?.rawDictionary` → `[String: Any]?` |
| Group | groupId | `payload.groupId` |
| Group | traits | `payload.traits` |
| Alias | newId | `payload.newId` |
| Alias | previousId | `payload.previousId` |

## Lifecycle Divergence

**ObjC v1**: The integration factory is registered before analytics init. The `initWithConfig:client:rudderConfig:` constructor runs synchronously during SDK startup. Lifecycle callbacks (`UIApplication` notifications) are registered at this point — before the app finishes launching.

**Swift SDK**: The integration plugin is added via `analytics.add(plugin:)`. The `create(destinationConfig:)` method fires **after** the SourceConfig is fetched from the control plane (async). This means:
- Lifecycle events that fire between app launch and SourceConfig fetch are **missed** in Swift
- Any `UIApplication.didBecomeActiveNotification` or `UIApplication.didFinishLaunchingNotification` observers registered in `create()` will not catch the initial app launch

This is a known divergence. Document it but do not try to work around it — it matches the Swift SDK's design.

## Config Access Pattern

### ObjC
```objc
NSString *apiKey = [config objectForKey:@"apiKey"];
BOOL enableFeature = [[config objectForKey:@"enableFeature"] boolValue];
```

### Swift
```swift
let apiKey = destinationConfig["apiKey"] as? String
let enableFeature = destinationConfig["enableFeature"] as? Bool ?? false
```

Always use optional casting (`as?`). Never force-cast config values.
