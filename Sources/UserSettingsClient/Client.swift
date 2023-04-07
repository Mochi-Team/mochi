//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/6/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture

public struct UserSettingsClient: Sendable {
    // TODO: Add client interface types
}

extension DependencyValues {
    public var userSettings: UserSettingsClient {
        get { self[UserSettingsClientKey.self] }
        set { self[UserSettingsClientKey.self] = newValue }
    }

    private enum UserSettingsClientKey: DependencyKey {
        static var liveValue = UserSettingsClient.live
        static var testValue = UserSettingsClient.unimplemented
    }
}
