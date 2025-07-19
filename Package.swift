// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GraphNext",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "GraphNext", targets: ["GraphNext"]),
        .library(name: "GraphPersistence", targets: ["GraphPersistence"]),
        .library(name: "GraphSyncEngine", targets: ["GraphSyncEngine"]),
        .library(name: "GraphAssets", targets: ["GraphAssets"])
    ],
    targets: [
        .target(name: "GraphNext"),
        .target(
            name: "GraphPersistence",
            dependencies: ["GraphNext"],
            resources: [
                .process("GraphNext.xcdatamodeld")
            ]
        ),
        .target(name: "GraphSyncEngine"),
        .target(name: "GraphAssets"),
        .testTarget(name: "GraphNextTests", dependencies: ["GraphNext"]),
        .testTarget(name: "GraphPersistenceTests", dependencies: ["GraphPersistence"]),
        .testTarget(name: "GraphSyncEngineTests", dependencies: ["GraphSyncEngine"]),
        .testTarget(name: "GraphAssetsTests", dependencies: ["GraphAssets"])
    ]
)

