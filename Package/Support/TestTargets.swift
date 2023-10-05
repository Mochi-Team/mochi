//
// TestTargets.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

protocol TestTargets: Sequence where Element == TestTarget {
  // swiftlint:disable:next identifier_name
  init<S>(_ s: S) where S.Element == TestTarget, S: Sequence
  func appending(_ testTargets: any TestTargets) -> Self
}
