// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GraphNext",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "GraphNext", targets: ["GraphNext"])
    ],
    targets: [
        .target(
            name: "GraphNext",
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
