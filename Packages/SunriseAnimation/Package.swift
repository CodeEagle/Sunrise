// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SunriseAnimation",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SunriseAnimation", targets: ["SunriseAnimation"])
    ],
    targets: [
        .target(name: "SunriseAnimation"),
        .testTarget(
            name: "SunriseAnimationTests",
            dependencies: ["SunriseAnimation"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
