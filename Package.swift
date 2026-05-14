// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SystemWatch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SystemWatch", targets: ["SystemWatch"])
    ],
    targets: [
        .executableTarget(
            name: "SystemWatch",
            path: "Sources/SystemWatch"
        )
    ]
)
