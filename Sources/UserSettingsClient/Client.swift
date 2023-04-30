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

public struct UserSettingsClient: Sendable {
    // TODO: Add client interface types
}

extension UserSettingsClient: TestDependencyKey {
    public static let testValue = Self()
}

extension DependencyValues {
    public var clientUserSettings: UserSettingsClient {
        get { self[UserSettingsClient.self] }
        set { self[UserSettingsClient.self] = newValue }
    }
}
