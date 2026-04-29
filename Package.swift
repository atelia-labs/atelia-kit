// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AteliaKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AteliaKit",
            targets: ["AteliaKit"]
        )
    ],
    targets: [
        .target(
            name: "AteliaKit"
        ),
        .testTarget(
            name: "AteliaKitTests",
            dependencies: ["AteliaKit"]
        )
    ]
)
