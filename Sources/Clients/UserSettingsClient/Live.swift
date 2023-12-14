//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Combine
import Dependencies
import Foundation

extension UserSettingsClient: DependencyKey {
  public static let liveValue: Self = {
    let userSettings = LockIsolated(UserSettings())
    let subject = PassthroughSubject<UserSettings, Never>()

    return Self {
      userSettings.value
    } set: { newValue in
      userSettings.withValue { state in
        state = newValue
        subject.send(newValue)
        print("Save settings")
      }
    } save: {
      // TODO: Save UserSettingsClient
      print("Save UserSettings")
    } stream: {
      subject.values.eraseToStream()
    }
  }()
}
