//
//  Client.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - UserSettingsClient

@dynamicMemberLookup
public struct UserSettingsClient: Sendable {
  public var get: @Sendable () -> UserSettings
  public var set: @Sendable (UserSettings) async -> Void
  public var save: @Sendable () async -> Void
  public var stream: @Sendable () -> AsyncStream<UserSettings>

  public subscript<Value>(dynamicMember keyPath: KeyPath<UserSettings, Value>) -> Value {
    self.get()[keyPath: keyPath]
  }

  @_disfavoredOverload
  public subscript<Value>(
    dynamicMember keyPath: KeyPath<UserSettings, Value>
  ) -> AsyncStream<Value> {
    self.stream().map { $0[keyPath: keyPath] }.eraseToStream()
  }

  public func modify(_ operation: (inout UserSettings) -> Void) async {
    var userSettings = self.get()
    operation(&userSettings)
    await self.set(userSettings)
  }
}

// MARK: TestDependencyKey

extension UserSettingsClient: TestDependencyKey {
  public static let testValue = Self(
    get: unimplemented(".get"),
    set: unimplemented(".set"),
    save: unimplemented(".save"),
    stream: unimplemented(".stream")
  )
}

extension DependencyValues {
  public var userSettings: UserSettingsClient {
    get { self[UserSettingsClient.self] }
    set { self[UserSettingsClient.self] = newValue }
  }
}
