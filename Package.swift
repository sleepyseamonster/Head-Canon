// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Voice Flow",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "VoiceFlow",
            targets: ["VoiceFlow"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "VoiceFlow"
        ),
        .testTarget(
            name: "VoiceFlowTests",
            dependencies: ["VoiceFlow"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
