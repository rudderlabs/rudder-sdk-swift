<p align="center">
  <a href="https://rudderstack.com/">
    <img src="https://user-images.githubusercontent.com/59817155/121357083-1c571300-c94f-11eb-8cc7-ce6df13855c9.png">
  </a>
</p>

<p align="center"><b>The Customer Data Platform for Developers</b></p>

<p align="center">
  <a href="https://cocoapods.org/pods/RudderStack">
    <img src="https://img.shields.io/cocoapods/v/RudderStack.svg?style=flat">
    </a>
</p>

<p align="center">
  <b>
    <a href="https://rudderstack.com">Website</a>
    ·
    <a href="https://rudderstack.com/docs/stream-sources/rudderstack-sdk-integration-guides/rudderstack-ios-sdk/">Documentation</a>
    ·
    <a href="https://rudderstack.com/join-rudderstack-slack-community">Community Slack</a>
  </b>
</p>

---

# RudderStack iOS SDK

RudderStack's iOS SDK lets you track event data from your **iOS**, **tvOS**, **watchOS** and **macOS** applications. After integrating the SDK, you will also be able to send these events to your preferred destinations such as Google Analytics, Amplitude, and more.

For detailed documentation on the iOS SDK, click [**here**](https://rudderstack.com/docs/stream-sources/rudderstack-sdk-integration-guides/rudderstack-ios-sdk).

## Installing the iOS SDK

The iOS SDK is available through [**CocoaPods**](https://cocoapods.org), [**Carthage**](https://github.com/Carthage/Carthage), and [**Swift Package Manager (SPM)**](https://www.swift.org/package-manager/).

### CocoaPods

To install the SDK, simply add the following line to your Podfile:

```xcode
pod 'RudderStack', '1.0.0-beta.2'
```

### Carthage

For Carthage support, add the following line to your `Cartfile`:

```xcode
github "rudderlabs/rudder-sdk-swift" "v1.0.0-beta.2"
```

> Remember to include the following code where you want to refer to or use the RudderStack SDK classes, as shown:
##### Objective C
```objective-c
@import RudderStack;
```
##### Swift
```swift
import RudderStack
```

### Swift Package Manager (SPM)

You can also add the RudderStack iOS SDK via Swift Package Mangaer, via one of the following two ways:

* [Xcode](#xcode)
* [Swift](#swift)

#### Xcode

* Go to **File** - **Add Package**, as shown:

![Adding a package](https://user-images.githubusercontent.com/59817155/140903027-286a1d64-f5d5-4041-9827-47b6cef76a46.png)

* Enter the package repository (`git@github.com:rudderlabs/rudder-sdk-swift.git`) in the search bar.

* In **Dependency Rule**, select **Up to Next Major Version** and enter `1.0.0-beta.2` as the value, as shown:

![Setting dependency](https://user-images.githubusercontent.com/59817155/145574696-8c849749-13e0-40d5-aacb-3fccb5c8e67d.png)

* Select the project to which you want to add the package.

* Finally, click on **Add Package**.

#### Swift

To leverage package.swift, use the following snippet in your project:

```swift
// swift-tools-version:5.5
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
        .package(url: "git@github.com:rudderlabs/rudder-sdk-swift.git", from: "1.0.0-beta.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RudderStack",
            dependencies: [
                .product(name: "RudderStack", package: "rudder-sdk-swift")
            ]),
        .testTarget(
            name: "RudderStackTests",
            dependencies: ["RudderStack"]),
    ]
)
```

## Initializing the RudderStack client

To the initialize `RSClient`, place the following code in your `AppDelegate` file under the method `didFinishLaunchingWithOptions`:
#### Objective C
```objective-c
RSConfig *config = [[RSConfig alloc] initWithWriteKey:WRITE_KEY];
[config dataPlaneURL:DATA_PLANE_URL];
[config recordScreenViews:YES];
RSClient *client = [[RSClient alloc] initWithConfig:config];
```
#### Swift
```swift
let config: RSConfig = RSConfig(writeKey: WRITE_KEY)
            .dataPlaneURL(DATA_PLANE_URL)
            .loglevel(.debug)
            .trackLifecycleEvents(true)
            .recordScreenViews(true)
let client = RSClient(config: config)
```

## Sending Events

### Track
##### Objective C
```objective-c
[client track:@"sample_track_call" properties:NULL option:NULL];
[client track:@"sample_track_call" properties:@{
    @"key_1" : @"value_1",
    @"key_2" : @"value_2"
} option:NULL];
```
#### Swift
```swift
client.track("sample_track_call")
client.track("sample_track_call", properties:[
    "key_1" : "value_1",
    "key_2" : "value_2"
])
```
### Screen
##### Objective C
```objective-c
[client screen:@"Main" properties:@{@"prop_key" : @"prop_value"} option:NULL];
```
#### Swift
```swift
client.screen("Main", properties:["prop_key" : "prop_value"]);
```
### Identify
##### Objective C
```objective-c
[client identify:@"test_user_id" traits:@{
    @"foo": @"bar",
    @"foo1": @"bar1",
    @"email": @"test@gmail.com"
} option:NULL];
```
#### Swift
```swift
client.identify("test_user_id", traits:[
    "foo": "bar",
    "foo1": "bar1",
    "email": "test@email.com"
])
```
### Group
##### Objective C
```objective-c
[client group:@"sample_group_id" traits:@{
    @"foo": @"bar", 
    @"foo1": @"bar1", 
    @"email": @"test@gmail.com"
} option:NULL];
```
#### Swift
```swift
client.group("sample_group_id" traits:[
    "foo": "bar", 
    "foo1": "bar1", 
    "email": "test@gmail.com"
])
```
### Alias
##### Objective C
```objective-c
[client alias:@"new_user_id" option:NULL];
```
#### Swift
```swift
client.alias("new_user_id")
```
### Reset
##### Objective C
```objective-c
[client reset];
```
#### Swift
```swift
client.reset()
```
For detailed documentation on the iOS SDK, click [**here**](https://rudderstack.com/docs/stream-sources/rudderstack-sdk-integration-guides/rudderstack-ios-sdk).

## Contribute

We would love to see you contribute to this project. Get more information on how to contribute [**here**](./CONTRIBUTING.md).

## About RudderStack

[**RudderStack**](https://rudderstack.com/) is a **customer data platform for developers**. Our tooling makes it easy to deploy pipelines that collect customer data from every app, website and SaaS platform, then activate it in your warehouse and business tools.

More information on RudderStack can be found [**here**](https://github.com/rudderlabs/rudder-server).

## Contact us

For more information on using the RudderStack iOS SDK, you can [**contact us**](https://rudderstack.com/contact/) or start a conversation on our [**Slack**](https://rudderstack.com/join-rudderstack-slack-community) channel.
