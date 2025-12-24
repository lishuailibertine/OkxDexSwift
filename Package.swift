// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OkxDexSwift",
    platforms: [
            .iOS(.v13),
            .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OkxDexSwift",
            targets: ["OkxDexSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.2.0"),
        .package(url: "https://github.com/mathwallet/web3swift", from: "3.5.3"),
        .package(url: "https://github.com/mathwallet/SolanaSwift", from: "5.1.5"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/lishuailibertine/SuiSwift", from: "1.1.1"),
        .package(url: "https://github.com/mathwallet/TonSwift", from: "0.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OkxDexSwift",
            dependencies: ["web3swift", "SolanaSwift", "CryptoSwift", "SuiSwift", "TonSwift", .product(name: "OrderedCollections", package: "swift-collections")],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "OkxDexSwiftTests",
            dependencies: ["OkxDexSwift"]
        ),
    ]
)
