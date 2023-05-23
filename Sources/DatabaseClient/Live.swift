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

extension DatabaseClient {
    public static var liveValue: DatabaseClient = {
        let core = CoreORM<MochiSchema>()
        return .init {
            try await core.load()
        } insert: { entity in
            _ = try await core.transaction { context in
                try await context.create(entity)
            }
        } insertOrUpdate: { entity in
            _ = try await core.transaction { context in
                try await context.createOrUpdate(entity)
            }
        } update: { entity in
            let instance = try? await core.transaction { context in
                try await context.update(entity)
            }
            return instance != nil
        } delete: { entity in
            try await core.transaction { context in
                try await context.delete(entity)
            }
        } fetch: { entityType, request in
            try await core.transaction { context in
                try await context.fetch(entityType, request)
            }
        } observe: { entityType, request in
            core.observe(entityType, request)
        }
    }()
}

enum DatabaseClientError: Error {
    case invalidRequestCastType
}

extension CoreORM {
    func observe<Instance: Entity>(_: Instance.Type, _ request: Any) -> AsyncStream<[Entity]> {
        self.observe((request as? Request<Instance>) ?? .all)
            .map { $0 as [Entity] }
            .eraseToStream()
    }
}

extension CoreTransaction {
    func fetch<Instance: Entity>(_: Instance.Type, _ request: Any) async throws -> [Instance] {
        try await self.fetch((request as? Request<Instance>) ?? .all)
    }
}
