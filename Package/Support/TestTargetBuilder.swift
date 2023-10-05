//
// TestTargetBuilder.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

@resultBuilder
enum TestTargetBuilder {
  static func buildPartialBlock(first: TestTarget) -> any TestTargets {
    [first]
  }

  static func buildPartialBlock(accumulated: any TestTargets, next: TestTarget) -> any TestTargets {
    accumulated + [next]
  }
}
