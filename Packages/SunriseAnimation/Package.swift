// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SunriseAnimation",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
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
