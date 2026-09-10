// swift-tools-version:5.3
// HyprMX adapter for Google AdMob mediation. Version 6.4.7.0
// CocoaPods podspec references the XCFramework zip from S3; SPM ships this target as source.
import PackageDescription

let package = Package(
    name: "HyprMX_AdMob",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "HyprMX_AdMob",
            targets: ["HyprMX_AdMob"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/JunGroupProductions/HyprMX-SDK-SPM.git", .exact("6.4.7")),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", "11.0.0"..<"14.0.0"),
    ],
    targets: [
        .target(
            name: "HyprMX_AdMob",
            dependencies: [
                .product(name: "HyprMX", package: "HyprMX-SDK-SPM"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "Sources/HyprMX-AdMob",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
            ]
        ),
    ]
)
