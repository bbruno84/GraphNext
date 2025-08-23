// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GraphNext",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "GraphNext", targets: ["GraphNext"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", exact: "7.6.1")
    ],
    targets: [
        .target(
            name: "GraphNext",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/GraphNext",
            resources: [
                // Modello Core Data all’interno del target principale
                .process("Persistence/Resources/GraphNext.xcdatamodeld")
            ],
            swiftSettings: [
                // Abilita sempre rtti minori e ottimizzazioni se vuoi
                // .unsafeFlags(["-enable-testing"], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "GraphNextTests",
            dependencies: ["GraphNext"],
            path: "Tests/GraphNextTests"
        )
    ]
)
