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
    <a href="https://rudderstack.com/docs/">Documentation</a>
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
- [Integrations](#integrations)
- [Contact us](#contact-us)
- [Follow Us](#follow-us)

---

## Installing the Swift SDK

### Swift Package Manager

Add the SDK to your Swift project using Swift Package Manager:

1. In Xcode, go to `File > Add Package Dependencies`

![Add Package Dependencies dialog in Xcode](https://github.com/user-attachments/assets/8fd3a216-14d9-43f2-83b0-2d639e9e974f)

2. Enter the package repository URL: `https://github.com/rudderlabs/rudder-sdk-swift` in the search bar.
3. Select the version you want to use
 
![Select package version in Xcode](https://github.com/user-attachments/assets/8a64c1df-4d97-45bb-9afd-0c38277eddf1)

4. Select the project to which you want to add the package.
5. Finally, click on **Add Package**.

![Add Package button in Xcode](https://github.com/user-attachments/assets/ebdf6203-a38e-44d5-a608-1a66d3841d74)

Alternatively, add it to your `Package.swift` file:

```swift
// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RudderStack",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RudderStack",
            targets: ["RudderStack"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/rudderlabs/rudder-sdk-swift.git", from: "<latest_version>")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RudderStack",
            dependencies: [
                .product(name: "RudderStackAnalytics", package: "rudder-sdk-swift")
            ]),
        .testTarget(
            name: "RudderStackTests",
            dependencies: ["RudderStack"]),
    ]
)
```

### Platform Support

The SDK supports the following platforms:
- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+

---

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
analytics?.identify(
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
analytics?.track(
    name: "Order Completed",
    properties: [
        "revenue": 30.0,
        "currency": "USD"
        ]
)
```

---

## Integrations

RudderStack Swift SDK supports various third-party integrations that allow you to send your event data to external analytics and marketing platforms. These integrations are implemented as separate modules that you can include in your project as needed.

### Available Integrations

The following integrations are currently available:

- [Adjust](https://github.com/rudderlabs/integration-swift-adjust) - Send your event data to Adjust for product analytics
- [AppsFlyer](https://github.com/rudderlabs/integration-swift-appsflyer) - Send your event data to AppsFlyer for mobile attribution and analytics
- [Braze](https://github.com/rudderlabs/integration-swift-braze) - Send your event data to Braze for customer engagement
- [Firebase](https://github.com/rudderlabs/integration-swift-firebase) - Send your event data to Google Firebase Analytics
- [Facebook](https://github.com/rudderlabs/integration-swift-facebook) - Send your event data to Facebook for analytics and advertising

### Using Integrations

To use an integration, follow these steps:

1. Add the integration dependency to your project using Swift Package Manager
2. Initialize the RudderStack SDK as usual
3. Add the integration to your Analytics instance

Example with multiple integrations:

```swift
import RudderStackAnalytics
import RudderIntegrationAdjust
import RudderIntegrationFirebase

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var analytics: Analytics?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the RudderStack Analytics SDK
        let config = Configuration(
            writeKey: "<WRITE_KEY>",
            dataPlaneUrl: "<DATA_PLANE_URL>"
        )
        self.analytics = Analytics(configuration: config)
        
        // Add integrations
        analytics?.add(plugin: AdjustIntegration())
        analytics?.add(plugin: FirebaseIntegration())
        // Add more integrations as needed
        
        return true
    }
}
```

---

## Contact us

For more information:

- Email us at [docs@rudderstack.com](mailto:docs@rudderstack.com)
- Join our [Community Slack](https://rudderstack.com/join-rudderstack-slack-community)

## Follow Us

- [RudderStack Blog](https://rudderstack.com/blog/)
- [Slack](https://rudderstack.com/join-rudderstack-slack-community)
- [Twitter](https://twitter.com/rudderstack)
- [YouTube](https://www.youtube.com/channel/UCgV-B77bV_-LOmKYHw8jvBw)
