//
// Target.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

protocol Target: _Depending, Dependency, _Named, _Path {
  var targetType: TargetType { get }

  @CSettingsBuilder
  var cSettings: [CSetting] { get }

  @SwiftSettingsBuilder
  var swiftSettings: [SwiftSetting] { get }

  @ResourcesBuilder
  var resources: [Resource] { get }
}

extension Target {
  var targetType: TargetType {
    .regular
  }

  var targetDepenency: _PackageDescription_TargetDependency {
    .target(name: self.name)
  }

  var cSettings: [CSetting] {
    []
  }

  var swiftSettings: [SwiftSetting] {
    []
  }

  var resources: [Resource] {
    []
  }
}
