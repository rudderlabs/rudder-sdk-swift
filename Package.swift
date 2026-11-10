// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "RudderStackAnalytics",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [.library(name: "RudderStackAnalytics", targets: ["RudderStackAnalytics"])],
    dependencies: [],
    targets: [.target(name: "RudderStackAnalytics", dependencies: [], resources: [.process("Resources")])]
)
