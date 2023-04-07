//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/6/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture
import Foundation

public struct UserDefaultsClient: Sendable {
    let doubleForKey: @Sendable (String) -> Double
    let intForKey: @Sendable (String) -> Int
    let boolForKey: @Sendable (String) -> Bool
    let dataForKey: @Sendable (String) -> Data?

    let setDouble: @Sendable (Double, String) async -> Void
    let setInt: @Sendable (Int, String) async -> Void
    let setBool: @Sendable (Bool, String) async -> Void
    let setData: @Sendable (Data?, String) async -> Void

    let remove: @Sendable (String) async -> Void
}

public extension UserDefaultsClient {
    func set(_ value: Double, forKey key: String) async {
        await self.setDouble(value, key)
    }

    func set(_ value: Int, forKey key: String) async {
        await self.setInt(value, key)
    }

    func set(_ value: Bool, forKey key: String) async {
        await self.setBool(value, key)
    }

    func set(_ value: Data?, forKey key: String) async {
        await self.setData(value, key)
    }

    func set<T: Codable>(_ value: T, forKey key: String) async throws {
        try await self.setData(JSONEncoder().encode(value), key)
    }
}

extension DependencyValues {
    public var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClientKey.self] }
        set { self[UserDefaultsClientKey.self] = newValue }
    }

    private enum UserDefaultsClientKey: DependencyKey {
        static var liveValue = UserDefaultsClient.live
        static var testValue = UserDefaultsClient.unimplemented
    }
}
