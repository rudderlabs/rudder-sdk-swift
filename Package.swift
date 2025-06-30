// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// License: Elastic License 2.0 (ELv2) – see LICENSE file for details

import PackageDescription

let package = Package(
    name: "RudderStackAnalytics",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "RudderStackAnalytics",
            targets: ["RudderStackAnalytics"]
        ),
    ],
    targets: [
        .target(name: "RudderStackAnalytics"),
        .testTarget(
            name: "RudderStackAnalyticsTests",
            dependencies: ["RudderStackAnalytics"],
            exclude: ["TestPlans"],  // Exclude Xcode-specific test plans
            resources: [
                .process("MockResources")  // Only include actual test resources
            ]
        ),
    ]
)
