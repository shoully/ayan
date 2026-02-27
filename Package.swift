// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ayan",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Ayan", targets: ["Ayan"])
    ],
    targets: [
        .executableTarget(
            name: "Ayan",
            path: "Sources/Ayan"
        )
    ]
)
