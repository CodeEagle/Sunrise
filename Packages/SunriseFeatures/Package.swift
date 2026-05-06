// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SunriseFeatures",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SunriseFeatures", targets: ["RootFeature"]),
        .library(name: "TodayFeature", targets: ["TodayFeature"]),
        .library(name: "ForecastFeature", targets: ["ForecastFeature"]),
        .library(name: "CharacterFeature", targets: ["CharacterFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0"),
        .package(path: "../SunriseCore"),
        .package(path: "../SunriseDesignSystem")
    ],
    targets: [
        .target(
            name: "RootFeature",
            dependencies: [
                "TodayFeature",
                "ForecastFeature",
                "CharacterFeature",
                "ProfileFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "TodayFeature",
            dependencies: [
                "SunriseCore",
                "SunriseDesignSystem",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ForecastFeature",
            dependencies: [
                "SunriseCore",
                "SunriseDesignSystem",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "CharacterFeature",
            dependencies: [
                "SunriseCore",
                "SunriseDesignSystem",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "ProfileFeature",
            dependencies: [
                "SunriseCore",
                "SunriseDesignSystem",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "TodayFeatureTests",
            dependencies: ["TodayFeature"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
