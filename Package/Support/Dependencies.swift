//
// Dependencies.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

protocol Dependencies: Sequence where Element == Dependency {
  // swiftlint:disable:next identifier_name
  init<S>(_ s: S) where S.Element == Dependency, S: Sequence
  func appending(_ dependencies: any Dependencies) -> Self
}
