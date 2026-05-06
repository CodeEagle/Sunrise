// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SunriseDesignSystem",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SunriseDesignSystem", targets: ["SunriseDesignSystem"])
    ],
    targets: [
        .target(
            name: "SunriseDesignSystem"
        )
    ],
    swiftLanguageVersions: [.v5]
)
