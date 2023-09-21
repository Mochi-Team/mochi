// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Features

let featuresTargets: [Target] = [
    .target(
        name: "App",
        dependencies: [
            "Architecture",
            "Discover",
            "Repos",
            "Search",
            "Settings",
            "SharedModels",
            "Styling",
            "UserSettingsClient",
            "VideoPlayer",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    ),
    .target(
        name: "Discover",
        dependencies: [
            "Architecture",
            "PlaylistDetails",
            "ModuleClient",
            "ModuleLists",
            "RepoClient",
            "Styling",
            "SharedModels",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    ),
    .target(
        name: "ModuleLists",
        dependencies: [
            "Architecture",
            "Styling",
            "RepoClient",
            "SharedModels",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "PlaylistDetails",
        dependencies: [
            "Architecture",
            "ContentCore",
            "LoggerClient",
            "ModuleClient",
            "RepoClient",
            "Styling",
            "SharedModels",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    ),
    .target(
        name: "Repos",
        dependencies: [
            "Architecture",
            "ModuleClient",
            "RepoClient",
            "SharedModels",
            "Styling",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    ),
    .target(
        name: "Search",
        dependencies: [
            "Architecture",
            "PlaylistDetails",
            "LoggerClient",
            "ModuleClient",
            "ModuleLists",
            "RepoClient",
            "Styling",
            "SharedModels",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    ),
    .target(
        name: "Settings",
        dependencies: [
            "Architecture",
            "Build",
            "SharedModels",
            "UserSettingsClient",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "VideoPlayer",
        dependencies: [
            "Architecture",
            "ContentCore",
            "LoggerClient",
            "PlayerClient",
            "SharedModels",
            "UserSettingsClient",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    )
]

let featuresProducts = featuresTargets
    .filter { $0.type == .regular && !$0.isTest }
    .map { target in
        Product.library(
            name: target.name,
            targets: [target.name]
        )
    }

// MARK: - Clients

let clientsTargets: [Target] = [
    .target(
        name: "AnalyticsClient",
        dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "DatabaseClient",
        dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "Semver", package: "Semver"),
            .product(name: "Tagged", package: "swift-tagged")
        ],
        resources: [
            .copy("Resources/MochiSchema.xcdatamodeld")
        ]
    ),
    .testTarget(
        name: "DatabaseClientTests",
        dependencies: ["DatabaseClient"]
    ),
    .target(
        name: "LoggerClient",
        dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "ModuleClient",
        dependencies: [
            "DatabaseClient",
            "SharedModels",
            "WasmInterpreter",
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "SwiftSoup", package: "SwiftSoup"),
            .product(name: "Semaphore", package: "Semaphore")
        ]
    ),
    .testTarget(
        name: "ModuleClientTests",
        dependencies: [
            "ModuleClient"
        ]
    ),
    .target(
        name: "RepoClient",
        dependencies: [
            "DatabaseClient",
            "SharedModels",
            .product(name: "TOMLDecoder", package: "TOMLDecoder"),
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "UserDefaultsClient",
        dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "UserSettingsClient",
        dependencies: [
            "UserDefaultsClient",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "PlayerClient",
        dependencies: [
            "Architecture",
            "DatabaseClient",
            "ModuleClient",
            "SharedModels",
            "Styling",
            "UserDefaultsClient",
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    )
]

let clientsProducts: [Product] = clientsTargets
    .filter { $0.type == .regular && !$0.isTest }
    .map {
        .library(
            name: $0.name,
            targets: [$0.name]
        )
    }

// MARK: - Miscellaneous

let miscTargets: [Target] = [
    .target(
        name: "Architecture",
        dependencies: [
            "FoundationHelpers",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "Build",
        dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "Semver", package: "Semver")
        ]
    ),
    .target(
        name: "ContentCore",
        dependencies: [
            "Architecture",
            "FoundationHelpers",
            "ModuleClient",
            "LoggerClient",
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "SharedModels",
        dependencies: [
            "DatabaseClient",
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "Semver", package: "Semver")
        ]
    ),
    .target(
        name: "Styling",
        dependencies: [
            "ViewComponents",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "SwiftUIBackports", package: "SwiftUIBackports")
        ]
    ),
    .target(
        name: "ViewComponents",
        dependencies: [
            "SharedModels",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            .product(name: "NukeUI", package: "Nuke")
        ]
    ),
    .target(
        name: "FoundationHelpers"
    ),
    .target(
        name: "WasmInterpreter",
        dependencies: [
            "CWasm3"
        ],
        cSettings: [
            .define("APPLICATION_EXTENSION_API_ONLY", to: "YES")
        ]
    ),
    .binaryTarget(
        name: "CWasm3",
        url: "https://github.com/shareup/cwasm3/releases/download/v0.5.2/CWasm3-0.5.0.xcframework.zip",
        checksum: "a2b0785be1221767d926cee76b087f168384ec9735b4f46daf26e12fae2109a3"
    ),
    .testTarget(
        name: "WasmInterpreterTests",
        dependencies: ["WasmInterpreter"],
        exclude: [
            "Resources/constant.wat",
            "Resources/constant.wasm",
            "Resources/memory.wat",
            "Resources/memory.wasm",
            "Resources/fib64.wat",
            "Resources/fib64.wasm",
            "Resources/imported-add.wat",
            "Resources/imported-add.wasm",
            "Resources/add.wat",
            "Resources/add.wasm"
        ]
    )
]

let miscProducs: [Product] = miscTargets
    .filter { $0.type == .regular && !$0.isTest }
    .map {
        .library(
            name: $0.name,
            targets: [$0.name]
        )
    }

// MARK: - Package

let package = Package(
    name: "core",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: featuresProducts + clientsProducts + miscProducs,
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-tagged", exact: "0.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.1.0"),
        .package(url: "https://github.com/kean/Nuke.git", exact: "12.1.5"),
        .package(url: "https://github.com/dduan/TOMLDecoder", from: "0.2.2"),
        .package(url: "https://github.com/kutchie-pelaez/Semver.git", exact: "1.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/groue/Semaphore", exact: "0.0.8"),
        .package(url: "https://github.com/shaps80/SwiftUIBackports.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: featuresTargets + clientsTargets + miscTargets
)
