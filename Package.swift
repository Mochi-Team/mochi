// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mochi",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WasmInterpreter",
            targets: ["WasmInterpreter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/shareup/cwasm3.git",
            exact: "0.5.3"
        )
    ],
    targets: [
        .target(
            name: "WasmInterpreter",
            dependencies: [
                .product(name: "CWasm3", package: "cwasm3")
            ]
        ),
        .testTarget(
            name: "WasmInterpreterTests",
            dependencies: ["WasmInterpreter"]
        )
    ]
)
