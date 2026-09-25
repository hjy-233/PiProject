// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MyBotService",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "MyBotCore", targets: ["MyBotCore"]),
        .executable(name: "mybot-server", targets: ["MyBotServer"]),
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
    ],
    targets: [
        .target(name: "MyBotCore"),
        .executableTarget(
            name: "MyBotServer",
            dependencies: [
                .product(name: "CSQLite", package: "CSQLite"),
                "MyBotCore",
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
        ),
        .testTarget(
            name: "MyBotServiceTests",
            dependencies: [
                "MyBotCore",
                "MyBotServer",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
        ),
    ],
)
