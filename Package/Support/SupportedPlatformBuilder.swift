//
// SupportedPlatformBuilder.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

import PackageDescription

@resultBuilder
enum SupportedPlatformBuilder {
  static func buildPartialBlock(first: SupportedPlatform) -> any SupportedPlatforms {
    [first]
  }

  static func buildPartialBlock(first: PlatformSet) -> any SupportedPlatforms {
    first.body
  }

  static func buildPartialBlock(first: any SupportedPlatforms) -> any SupportedPlatforms {
    first
  }

  static func buildPartialBlock(
    accumulated: any SupportedPlatforms,
    next: any SupportedPlatforms
  ) -> any SupportedPlatforms {
    accumulated.appending(next)
  }

  static func buildPartialBlock(
    accumulated: any SupportedPlatforms,
    next: SupportedPlatform
  ) -> any SupportedPlatforms {
    accumulated.appending([next])
  }
}
