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
    // TODO: Add client interface types
    public let get: @Sendable () -> UserSettings
    public let set: @Sendable (UserSettings) async -> Void
    public let stream: @Sendable () -> AsyncStream<UserSettings>

    public subscript<Value>(dynamicMember keyPath: KeyPath<UserSettings, Value>) -> Value {
        self.get()[keyPath: keyPath]
    }

    @_disfavoredOverload
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<UserSettings, Value>
    ) -> AsyncStream<Value> {
        // TODO: This should probably remove duplicates.
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
        stream: unimplemented(".stream")
    )
}

public extension DependencyValues {
    var userSettings: UserSettingsClient {
        get { self[UserSettingsClient.self] }
        set { self[UserSettingsClient.self] = newValue }
    }
}
