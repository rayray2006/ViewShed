// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ViewShed",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ViewShed",
            targets: ["ViewShed"]
        )
    ],
    dependencies: [
        // MapBox Maps SDK - pinned to exact version to avoid slow re-resolution
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: "11.6.1"),
        // Turf for geographic calculations
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "2.8.0")
    ],
    targets: [
        .target(
            name: "ViewShed",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "Turf", package: "turf-swift")
            ]
        ),
        .testTarget(
            name: "ViewShedTests",
            dependencies: ["ViewShed"]
        )
    ]
)
