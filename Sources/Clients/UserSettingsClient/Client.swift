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

public struct UserSettingsClient: Sendable {
    // TODO: Add client interface types
}

// MARK: TestDependencyKey

extension UserSettingsClient: TestDependencyKey {
    public static let testValue = Self()
}

public extension DependencyValues {
    var userSettings: UserSettingsClient {
        get { self[UserSettingsClient.self] }
        set { self[UserSettingsClient.self] = newValue }
    }
}
