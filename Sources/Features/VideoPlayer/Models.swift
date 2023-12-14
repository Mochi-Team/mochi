//
//  Models.swift
//
//
//  Created by ErrorErrorError on 11/22/23.
//
//

import Foundation

public struct PlayerSettings: Equatable, Sendable {
  // Quarterly
  public var speed = 1.0

  // In Seconds
  public var skipTime = 15.0

  public init(speed: Double = 1.0) {
    self.speed = speed
  }
}
