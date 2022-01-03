// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CheckLocalizedStrings",
    platforms: [.macOS(.v10_12)],
    products: [
        .executable(name: "CheckLocalizedStrings", targets: ["CheckLocalizedStrings"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(name: "CheckLocalizedStrings")
    ]
)
