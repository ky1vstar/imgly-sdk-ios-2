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
            exclude: [
                "Supporting Files",
                "Backend/Processing/ObjC"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "imglyKit-ObjC",
            path: "imglyKit/Backend/Processing/ObjC",
            publicHeadersPath: ""
        )
    ]
)
