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
            targets: ["OMSDK"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "OMSDKFramework",
            path: "Frameworks/OMSDK_Loblawca.xcframework"
        ),
        .target(
            name: "OMSDK",
            dependencies: ["OMSDKFramework"],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        )
    ]
)
