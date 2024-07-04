//
//  Models.swift
//
//
//  Created by MochiTeam on 11/22/23.
//
//

import Foundation

public struct PlayerSettings: Equatable, Sendable {
  // Quarterly
  public var speed = 1.0

  // In Seconds
  public var skipForwardTime = UserDefaults.standard.double(forKey: "userSettings.fastForwardAmount")
  public var skipBackwardTime = UserDefaults.standard.double(forKey: "userSettings.fastBackwardAmount")

  public init(speed: Double = 1.0) {
    self.speed = speed
  }
}
