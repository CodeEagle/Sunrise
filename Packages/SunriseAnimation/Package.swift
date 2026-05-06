// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SunriseAnimation",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SunriseAnimation", targets: ["SunriseAnimation"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm", from: "4.5.0")
    ],
    targets: [
        .target(
            name: "SunriseAnimation",
            dependencies: [
                .product(name: "Lottie", package: "lottie-spm")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
