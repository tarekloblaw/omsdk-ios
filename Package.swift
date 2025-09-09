// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "OMSDK",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "OMSDK",
            targets: ["OMSDK", "OMSDK_Loblawca"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "OMSDK_Loblawca",
            path: "Frameworks/OMSDK_Loblawca.xcframework"
        ),
        .target(
            name: "OMSDK",
            dependencies: ["OMSDK_Loblawca"],
            resources: [
                .copy("omsdk-v1.js")
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE"),
                .define("SDUI_INTERNAL")
            ]
        )
    ]
)
