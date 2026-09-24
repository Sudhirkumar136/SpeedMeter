// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NetMeter",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "NetMeter", targets: ["NetMeterApp"])
    ],
    targets: [
        .target(name: "NetMeterCore"),
        .executableTarget(name: "NetMeterApp", dependencies: ["NetMeterCore"]),
        .testTarget(name: "NetMeterCoreTests", dependencies: ["NetMeterCore"])
    ]
)
