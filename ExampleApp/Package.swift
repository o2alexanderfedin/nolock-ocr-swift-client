// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExampleApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "ExampleApp",
            dependencies: [
                .product(name: "NolockOCRClient", package: "nolock-ocr-swift-client")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)