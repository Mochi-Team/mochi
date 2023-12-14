//
//  Client.swift
//
//
//  Created ErrorErrorError on 4/6/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - UserDefaultsClient

public struct UserDefaultsClient: Sendable {
  var doubleForKey: @Sendable (String) -> Double
  var intForKey: @Sendable (String) -> Int
  var boolForKey: @Sendable (String) -> Bool
  var dataForKey: @Sendable (String) -> Data?

  var setDouble: @Sendable (Double, String) async -> Void
  var setInt: @Sendable (Int, String) async -> Void
  var setBool: @Sendable (Bool, String) async -> Void
  var setData: @Sendable (Data?, String) async -> Void

  var remove: @Sendable (String) async -> Void
}

// MARK: TestDependencyKey

extension UserDefaultsClient: TestDependencyKey {
  public static let testValue = Self(
    doubleForKey: unimplemented("\(Self.self).doubleForKey is unimplemented."),
    intForKey: unimplemented("\(Self.self).intForKey is unimplemented."),
    boolForKey: unimplemented("\(Self.self).boolForKey is unimplemented."),
    dataForKey: unimplemented("\(Self.self).dataForKey is unimplemented."),
    setDouble: unimplemented("\(Self.self).setDouble is unimplemented."),
    setInt: unimplemented("\(Self.self).setInt is unimplemented."),
    setBool: unimplemented("\(Self.self).setBool is unimplemented."),
    setData: unimplemented("\(Self.self).setData is unimplemented."),
    remove: unimplemented("\(Self.self).remove is unimplemented.")
  )
}

extension DependencyValues {
  public var userDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}
