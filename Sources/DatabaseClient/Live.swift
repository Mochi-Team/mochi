//
//  Live.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import CoreORM
import Dependencies
import Foundation
import XCTestDynamicOverlay

final class DatabaseClientLive: DatabaseClient {
    let core: CoreORM<MochiSchema>

    init() {
        core = .init()
    }

    @Sendable
    func initialize() async throws {
        try await core.load()
    }

    @Sendable
    func insert<T: Entity>(_ item: T) async throws {
        try await core.transaction { context in
            try await context.create(item)
        }
    }

    @Sendable
    func update<T: Entity>(_ item: T) async throws -> Bool {
        let instance = try? await core.transaction { context in
            try await context.update(item)
        }
        return instance != nil
    }

    @Sendable
    func insertOrUpdate<T: Entity>(_ item: T) async throws {
        try await core.transaction { context in
            try await context.createOrUpdate(item)
        }
    }

    func delete<T: Entity>(_ item: T) async throws {
        try await core.transaction { context in
            try await context.delete(item)
        }
    }

    func fetch<T: Entity>(_ request: Request<T>) async throws -> [T] {
        try await core.transaction { context in
            try await context.fetch(request)
        }
    }

    func observe<T: Entity>(_ request: Request<T>) -> AsyncStream<[T]> {
        core.observe(request)
    }
}
