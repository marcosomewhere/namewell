// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Namewell",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Namewell",
            path: "Namewell",
            exclude: [
                "Info.plist",
                "Namewell.entitlements",
            ],
            resources: [
                .process("Resources"),
                .process("Assets.xcassets"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NamewellTests",
            dependencies: ["Namewell"],
            path: "NamewellTests"
        )
    ]
)
