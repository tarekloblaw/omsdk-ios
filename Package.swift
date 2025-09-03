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
            path: "Frameworks/OMSDK-Static_Loblawca.xcframework"
        ),
        .target(
            name: "OMSDK",
            dependencies: ["OMSDKFramework"],
            publicHeadersPath: "include",
            cSettings: [
                .define("SDUI_INTERNAL")
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE"),
                .define("SDUI_INTERNAL")
            ]
        )
    ]
)
