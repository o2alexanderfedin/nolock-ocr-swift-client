// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MinimalOCRApp",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "MinimalOCRApp",
            dependencies: [
                .product(name: "NolockOCRClient", package: "nolock-ocr-swift-client")
            ],
            path: "MinimalOCRApp"
        )
    ]
)