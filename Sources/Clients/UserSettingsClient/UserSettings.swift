//
//  UserSettings.swift
//
//
//  Created by MochiTeam on 5/19/23.
//
//

public struct UserSettings: Sendable, Equatable, Codable {
  public var theme: Theme
  public var fastForwardAmount: Double
  public var fastBackwardAmount: Double
  public var appIcon: AppIcon
  public var developerModeEnabled: Bool

  public init(
    theme: Theme? = .automatic,
    appIcon: AppIcon = .default,
    developerModeEnabled: Bool = false,
    fastForwardAmount: Double? = 15,
    fastBackwardAmount: Double? = 5
  ) {
    self.theme = theme ?? .automatic
    self.appIcon = appIcon
    self.developerModeEnabled = developerModeEnabled
    self.fastForwardAmount = fastForwardAmount ?? 15
    self.fastBackwardAmount = fastBackwardAmount ?? 5
  }
}
