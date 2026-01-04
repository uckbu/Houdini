// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Houdini",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "Houdini", targets: ["Houdini"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Houdini",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("Cocoa")
            ]
        )
    ]
)
