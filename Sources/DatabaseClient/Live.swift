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

public extension DatabaseClient {
    static var liveValue: DatabaseClient = {
        let core = CoreORM<MochiSchema>()
        return .init {
            try await core.load()
        } insert: { entity in
            try await core.transaction { context in
                try await context.create(entity)
            }
        } insertOrUpdate: { entity in
            try await core.transaction { context in
                try await context.createOrUpdate(entity)
            }
        } update: { entity in
            try await core.transaction { context in
                try await context.update(entity)
            }
        } delete: { entity in
            try await core.transaction { context in
                try await context.delete(entity)
            }
        } fetch: { entityType, request in
            try await core.transaction { context in
                try await context.fetch(entityType, request)
            }
        }
    }()
}

// MARK: - DatabaseClientError

enum DatabaseClientError: Error {
    case invalidRequestCastType
}

extension CoreTransaction {
    func fetch<Instance: Entity>(_: Instance.Type, _ request: Any) async throws -> [Instance] {
        try await fetch((request as? Request<Instance>) ?? .all)
    }
}
