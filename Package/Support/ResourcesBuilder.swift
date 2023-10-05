//
// ResourcesBuilder.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

@resultBuilder
enum ResourcesBuilder {
  static func buildPartialBlock(first: Resource) -> [Resource] {
    [first]
  }

  static func buildPartialBlock(accumulated: [Resource], next: Resource) -> [Resource] {
    accumulated + [next]
  }
}
