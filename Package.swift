// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Head Canon",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "HeadCanon",
            targets: ["HeadCanon"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "HeadCanon"
        ),
        .testTarget(
            name: "HeadCanonTests",
            dependencies: ["HeadCanon"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
