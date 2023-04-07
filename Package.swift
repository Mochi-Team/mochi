// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Features

let featuresProducts: [Product] = [
    .library(
        name: "App",
        targets: ["App"]
    ),
    .library(
        name: "Home",
        targets: ["Home"]
    ),
    .library(
        name: "Settings",
        targets: ["Settings"]
    )
]

let featuresTargets: [Target] = [
    .target(
        name: "App",
        dependencies: [
            "Architecture",
            "Home",
            "SharedModels",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "Home",
        dependencies: [
            "Architecture",
            "SharedModels",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    ),
    .target(
        name: "Settings",
        dependencies: [
            "Architecture",
            "SharedModels",
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ]
    )
]

// MARK: - Clients

let clientsProducts: [Product] = [
    .library(
        name: "UserDefaultsClient",
        targets: ["UserDefaultsClient"]
    ),
    .library(
        name: "UserSettingsClient",
        targets: ["UserSettingsClient"]
    )
]

let clientsTargets: [Target] = [
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
    )
]

// MARK: - Miscellaneous

let miscProducs: [Product] = [
    .library(
        name: "Architecture",
        targets: ["Architecture"]
    ),
    .library(
        name: "SharedModels",
        targets: ["SharedModels"]
    ),
    .library(
        name: "WasmInterpreter",
        targets: ["WasmInterpreter"]
    )
]

let miscTargets: [Target] = [
    .target(
        name: "Architecture",
        dependencies: [
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        ]
    ),
    .target(
        name: "SharedModels",
        dependencies: [
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        ]
    ),
    .target(
        name: "WasmInterpreter",
        dependencies: [
            "CWasm3",
        ],
        cSettings: [
            .define("APPLICATION_EXTENSION_API_ONLY", to: "YES"),
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
            "Resources/add.wasm",
        ]
    )
]
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
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", revision: "fc17996ded63b136741ab2e0c0e0d549a8486adc"),
        .package(url: "https://github.com/johnpatrickmorgan/TCACoordinators.git", exact: "0.4.0")
    ],
    targets: featuresTargets + clientsTargets + miscTargets
)
