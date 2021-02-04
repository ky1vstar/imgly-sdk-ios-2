// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "imglyKit",
    defaultLocalization: .resolved(),
    platforms: [
        .iOS(.v9), .macOS(.v10_10),
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

private extension LanguageTag {
    static func resolved() -> LanguageTag? {
        #if os(iOS)
        return .init("en")
        #elseif os(macOS)
        return nil
        #endif
    }
}

private enum Exclude {
    static func common() -> [String] {
        [
            "Supporting Files",
            "Backend/Processing/ObjC"
        ]
    }
    
    static func platform() -> [String] {
        #if os(iOS)
        return []
        #elseif os(macOS)
        return [
            "Frontend",
        ]
        #endif
    }
    
    static func resolved() -> [String] {
        common() + platform()
    }
}

private extension Resource {
    static func common() -> [Self] {
        [
            .process("Backend/Filter Responses"),
            .process("Backend/Fonts")
        ]
    }
    
    static func platform() -> [Self] {
        #if os(iOS)
        return []
        #elseif os(macOS)
        return []
        #endif
    }
    
    static func resolved() -> [Self] {
        common() + platform()
    }
}
