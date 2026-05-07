// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SunriseDesignSystem",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
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
