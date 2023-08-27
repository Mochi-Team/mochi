//
//  Client.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import CoreORM
import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - DatabaseClient

public struct DatabaseClient: Sendable {
    public var initialize: @Sendable () async throws -> Void
    public var insert: @Sendable (any Entity) async throws -> Entity
    public var insertOrUpdate: @Sendable (any Entity) async throws -> Entity
    public var update: @Sendable (any Entity) async throws -> Entity
    public var delete: @Sendable (any Entity) async throws -> Void
    var fetch: @Sendable (Entity.Type, Any) async throws -> [Entity]
}

public extension DatabaseClient {
    func fetch<T: Entity>(_ request: Request<T>) async throws -> [T] {
        try await (fetch(T.self, request) as? [T]) ?? []
    }
}

// MARK: DependencyKey

extension DatabaseClient: DependencyKey {}

public extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
