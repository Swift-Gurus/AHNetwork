// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AHNetwork",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "AHNetwork",
            targets: ["AHNetwork"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swift-Gurus/FunctionalSwift.git", 
                 branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "AHNetwork",
            dependencies: [
                .product(name: "FunctionalSwift",
                         package: "FunctionalSwift")
            ]),
        .testTarget(
            name: "AHNetworkTests",
            dependencies: [
                "AHNetwork",
                .product(name: "FunctionalSwift",
                         package: "FunctionalSwift"
                         )
                ])
    ]
)
