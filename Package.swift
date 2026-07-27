// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NotificationsEngine",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NotificationsEngine",
            targets: ["NotificationsEngine"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "Firebase",
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "12.0.0")
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        // ponytail: pinned to Swift 5 semantics. tools-version 6.0 is here for
        // `.iOS(.v18)`, not for a concurrency migration — drop this to adopt Swift 6.
        .target(
            name: "NotificationsEngine",
            dependencies: [
                .product(
                    name: "FirebaseMessaging",
                    package: "Firebase"
                )
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
