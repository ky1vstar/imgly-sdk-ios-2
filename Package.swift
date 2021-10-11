// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "imglyKit",
    defaultLocalization: .init("en"),
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
            exclude: [
                "Supporting Files",
                "Backend/Processing/ObjC"
            ],
            resources: [
                .process("Backend/Filter Responses"),
                .process("Backend/Fonts")
            ]
        ),
        .target(
            name: "imglyKit-ObjC",
            path: "imglyKit/Backend/Processing/ObjC",
            publicHeadersPath: ""
        )
    ]
)