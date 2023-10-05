//
// _PackageDescription_Product.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension _PackageDescription_Product {
  static func entry(_ entry: Product) -> _PackageDescription_Product {
    let targets = entry.productTargets.map(\.name)

    switch entry.productType {
    case .executable:
      return Self.executable(name: entry.name, targets: targets)

    case .library:
      return Self.library(name: entry.name, targets: targets)
    }
  }
}
