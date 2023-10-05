//
// TargetType.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

//typealias TargetType = Target.TargetType

enum TargetType {
  case regular
  case executable
  case test
  case binary(BinaryTarget)

  enum BinaryTarget {
    case path(String)
    case remote(url: String, checksum: String)
  }
}
