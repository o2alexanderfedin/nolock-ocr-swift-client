// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalPackages",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LocalPackages",
            targets: ["LocalPackages"]),
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "LocalPackages",
            dependencies: [
                .product(name: "NolockOCRClient", package: "NolockOCRClient")
            ])
    ]
)