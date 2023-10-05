//
// Array+SupportedPlatforms.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension Array: SupportedPlatforms where Element == SupportedPlatform {
  func appending(_ platforms: any SupportedPlatforms) -> Self {
    self + .init(platforms)
  }
}
