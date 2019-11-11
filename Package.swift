// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "imglyKit",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "imglyKit",
            targets: ["imglyKit"]
        )
    ],
    dependencies: []
)
