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

public struct DatabaseClient: Sendable {
    public var initialize: @Sendable () async throws -> Void

    public var insert: @Sendable (any Entity) async throws -> Void

    public var insertOrUpdate: @Sendable (any Entity) async throws -> Void

    public var update: @Sendable (any Entity) async throws -> Bool

    public var delete: @Sendable (any Entity) async throws -> Void

    var fetch: @Sendable (Entity.Type, Any) async throws -> [Entity]

    var observe: @Sendable (Entity.Type, Any) -> AsyncStream<[Entity]>
}

public extension DatabaseClient {
    func fetch<T: Entity>(_ request: Request<T>) async throws -> [T] {
        ((try await self.fetch(T.self, request)) as? [T]) ?? []
    }

    func observe<T: Entity>(_ request: Request<T>) -> AsyncStream<[T]> {
        self.observe(T.self, request)
            .compactMap { $0 as? [T] }
            .eraseToStream()
    }
}

extension DatabaseClient: DependencyKey {}

extension DependencyValues {
    public var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
