//
// _PackageDescription_Target.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension _PackageDescription_Target {
  static func entry(_ entry: Target, swiftSettings: [SwiftSetting] = []) -> _PackageDescription_Target {
    let dependencies = entry.dependencies.map(\.targetDepenency)
    switch entry.targetType {
    case .executable:
      return .executableTarget(
        name: entry.name,
        dependencies: dependencies,
        path: entry.path,
        resources: entry.resources,
        cSettings: entry.cSettings,
        swiftSettings: swiftSettings + entry.swiftSettings
      )

    case .regular:
      return .target(
        name: entry.name,
        dependencies: dependencies,
        path: entry.path,
        resources: entry.resources,
        cSettings: entry.cSettings,
        swiftSettings: swiftSettings + entry.swiftSettings
      )

    case .test:
      return .testTarget(
        name: entry.name,
        dependencies: dependencies,
        path: entry.path,
        resources: entry.resources,
        cSettings: entry.cSettings,
        swiftSettings: swiftSettings + entry.swiftSettings
      )

    case .binary(.path(let path)):
      return .binaryTarget(
        name: entry.name,
        path: path
      )

    case .binary(.remote(let url, let checksum)):
      return .binaryTarget(
        name: entry.name,
        url: url,
        checksum: checksum
      )
    }
  }
}
