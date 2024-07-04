//
//  Live.swift
//
//
//  Created MochiTeam on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Combine
import Dependencies
import Foundation

extension UserSettingsClient: DependencyKey {
  public static let liveValue: Self = {
    let userSettings = LockIsolated(UserSettings(
    developerModeEnabled: UserDefaults.standard.bool(forKey: "userSettings.developerModeEnabled"),
    fastForwardAmount: UserDefaults.standard.value(forKey: "userSettings.fastForwardAmount") as? Double,
    fastBackwardAmount: UserDefaults.standard.value(forKey: "userSettings.fastBackwardAmount") as? Double
    ))
    let subject = PassthroughSubject<UserSettings, Never>()

    return Self {
      userSettings.value
    } set: { newValue in
      userSettings.withValue { state in
        state = newValue
        subject.send(newValue)
        print("Save settings")
        UserDefaults.standard.setValue(newValue.fastForwardAmount, forKey: "userSettings.fastForwardAmount")
        UserDefaults.standard.setValue(newValue.fastBackwardAmount, forKey: "userSettings.fastBackwardAmount")
        UserDefaults.standard.setValue(newValue.developerModeEnabled, forKey: "userSettings.developerModeEnabled")
      }
    } save: {
      // TODO: Save UserSettingsClient
      print("Save UserSettings")
    } stream: {
      subject.values.eraseToStream()
    }
  }()
}
