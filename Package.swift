// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "RudderStack",
    platforms: [
        .iOS("12.0"), .tvOS("11.0"), .macOS("10.13"), .watchOS("7.0")
    ],
    products: [
        .library(
            name: "RudderStack",
            targets: ["RudderStack"]
        )
    ],
    targets: [
        .target(
            name: "RudderStack",
            path: "Sources",
            sources: ["Classes/"]
        ),
        .testTarget(
            name: "RudderStackTests",
            dependencies: ["RudderStack"]
        )
    ]
)
