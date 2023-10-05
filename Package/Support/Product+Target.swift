//
// Product+Target.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension Product where Self: Target {
  var productTargets: [Target] {
    [self]
  }

  var targetType: TargetType {
    switch self.productType {
    case .library:
      return .regular

    case .executable:
      return .executable
    }
  }
}
