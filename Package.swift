// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DevBuddyCompanion",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DevBuddyCompanion",
            path: "DevBuddyCompanion",
            exclude: ["Info.plist"]
        )
    ]
)
