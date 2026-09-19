// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ProjectDeployerService",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "project-deployer-service",
            targets: ["ProjectDeployerService"],
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/hummingbird-project/hummingbird.git",
            exact: "2.26.0",
        ),
        .package(
            url: "https://github.com/apple/swift-log.git",
            exact: "1.15.1",
        ),
    ],
    targets: [
        .executableTarget(
            name: "ProjectDeployerService",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .unsafeFlags(
                    ["-cross-module-optimization"],
                    .when(configuration: .release),
                ),
            ],
        ),
        .testTarget(
            name: "ProjectDeployerServiceTests",
            dependencies: [
                "ProjectDeployerService",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
        ),
    ],
)
