//
// SwiftSettingsBuilder.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

@resultBuilder
enum SwiftSettingsBuilder {
  static func buildPartialBlock(first: SwiftSetting) -> [SwiftSetting] {
    [first]
  }

  static func buildPartialBlock(accumulated: [SwiftSetting], next: SwiftSetting) -> [SwiftSetting] {
    accumulated + [next]
  }
}
