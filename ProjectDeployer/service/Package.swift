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
            url: "https://github.com/sbooth/CSQLite.git",
            exact: "3.53.4",
        ),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird.git",
            exact: "2.26.0",
        ),
        .package(
            url: "https://github.com/apple/swift-log.git",
            exact: "1.15.1",
        ),
        .package(
            url: "https://github.com/swift-server/swift-service-lifecycle.git",
            exact: "2.12.0",
        ),
    ],
    targets: [
        .executableTarget(
            name: "ProjectDeployerService",
            dependencies: [
                .product(name: "CSQLite", package: "CSQLite"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
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
