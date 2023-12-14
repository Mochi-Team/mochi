//
//  Model.swift
//
//
//  Created by ErrorErrorError on 11/27/23.
//
//

import Foundation
import Semver
import Tagged

// MARK: - Build

public struct Build: Equatable, Sendable {
  public let version: Semver
  public let number: Number

  public typealias Number = Tagged<((), number: ()), Int>
}

// MARK: - Semver + Sendable

extension Semver: @unchecked Sendable {}
