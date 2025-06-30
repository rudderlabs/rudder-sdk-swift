<p align="center">
  <a href="https://rudderstack.com/">
    <img alt="RudderStack" width="512" src="https://raw.githubusercontent.com/rudderlabs/rudder-sdk-js/develop/assets/rs-logo-full-light.jpg">
  </a>
  <br />
  <caption>The Customer Data Platform for Developers</caption>
</p>
<p align="center">
  <b>
    <a href="https://rudderstack.com">Website</a>
    ·
    <a href="https://rudderstack.com/docs/stream-sources/rudderstack-sdk-integration-guides/rudderstack-javascript-sdk/">Documentation</a>
    ·
    <a href="https://rudderstack.com/join-rudderstack-slack-community">Community Slack</a>
  </b>
</p>

---

# RudderStack Swift SDK

The Swift SDK enables you to track customer event data from your iOS, macOS, tvOS, and watchOS applications and send it to your configured destinations via RudderStack.

## Table of Contents

- [Installing the Swift SDK](#installing-the-swift-sdk)
- [Initializing the SDK](#initializing-the-sdk)
- [Identifying users](#identifying-users)
- [Tracking user actions](#tracking-user-actions)
- [Contribute](#contribute)
- [Contact us](#contact-us)
- [Follow Us](#follow-us)

---

## Installing the Swift SDK

### Swift Package Manager

Add the SDK to your Swift project using Swift Package Manager:

1. In Xcode, go to `File > Add Package Dependencies`
2. Enter the repository URL: `https://github.com/rudderlabs/rudder-sdk-swift`
3. Select the version you want to use

Alternatively, add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/rudderlabs/rudder-sdk-swift", from: "1.0.0")
]
```

### Platform Support

The SDK supports the following platforms:
- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+

## Initializing the SDK

To initialize the RudderStack Swift SDK, add the Analytics initialization snippet to your application's entry point:

```swift
import RudderStackAnalytics

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var analytics: Analytics?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the RudderStack Analytics SDK
        let config = Configuration(
            writeKey: "<WRITE_KEY>",
            dataPlaneUrl: "<DATA_PLANE_URL>"
        )
        self.analytics = Analytics(configuration: config)
        
        return true
    }
}
```

Replace:
- `<WRITE_KEY>`: Your project's write key from the RudderStack dashboard.
- `<DATA_PLANE_URL>`: The URL of your RudderStack data plane.

## Identifying users

The `identify` API lets you recognize a user and associate them with their traits:

```swift
analytics.identify(
    userId: "1hKOmRA4el9Zt1WSfVJIVo4GRlm",
    traits: [
        "name": "Alex Keener",
        "email": "alex@example.com"
    ]
)
```

## Tracking user actions

The `track` API lets you capture user events:

```swift
analytics.track(
    name: "Order Completed",
    properties: [
        "revenue": 30.0,
        "currency": "USD"
        ]
)
```

## Contact us

For more information:

- Email us at [docs@rudderstack.com](mailto:docs@rudderstack.com)
- Join our [Community Slack](https://rudderstack.com/join-rudderstack-slack-community)

## Follow Us

- [RudderStack Blog](https://rudderstack.com/blog/)
- [Slack](https://rudderstack.com/join-rudderstack-slack-community)
- [Twitter](https://twitter.com/rudderstack)
- [YouTube](https://www.youtube.com/channel/UCgV-B77bV_-LOmKYHw8jvBw)
