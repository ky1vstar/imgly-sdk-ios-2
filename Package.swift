// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "imglyKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "imglyKit",
            targets: ["imglyKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "imglyKit",
            dependencies: ["imglyKit-ObjC"],
            path: "imglyKit",
            exclude: Exclude.resolved(),
            resources: Resource.resolved()
        ),
        .target(
            name: "imglyKit-ObjC",
            path: "imglyKit/Backend/Processing/ObjC",
            publicHeadersPath: ""
        )
    ]
)

private enum Exclude {
    static func common() -> [String] {
        [
            "Supporting Files",
            "Backend/Processing/ObjC"
        ]
    }
    
    static func platform() -> [String] {
        return []
    }
    
    static func resolved() -> [String] {
        common() + platform()
    }
}

private extension Resource {
    static func common() -> [Self] {
        [
            .process("Backend/Filter Responses"),
            .process("Backend/Fonts"),
            .process("Resources")
        ]
    }
    
    static func resolved() -> [Self] {
        common()
    }
}
