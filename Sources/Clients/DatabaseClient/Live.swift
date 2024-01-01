//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import CoreData
import CoreDB
import Dependencies
import Foundation
import XCTestDynamicOverlay

extension DatabaseClient {
  public static var liveValue: DatabaseClient = {
    let container = PersistentCoreDB<MochiSchema>()
    return .init {
      try await container.load()
    } insert: { instance in
      try await container.transaction { transaction in
        try await transaction.create(instance)
      }
    } update: { instance in
      try await container.transaction { transaction in
        try await transaction.update(instance)
      }
    } delete: { instance in
      try await container.transaction { transaction in
        try await transaction.delete(instance)
      }
    } fetch: { entityType, requestType in
      try await container.transaction { transaction in
        try await transaction.fetch(entityType, requestType)
      }
    } observe: { entityType, requestType in
      container.observe(entityType, requestType)
    }
  }()
}

// MARK: - DatabaseClientError

enum DatabaseClientError: Error {
  case invalidRequestCastType
}

extension PersistentCoreDB {
  fileprivate func observe<Instance: Entity>(
    _: Instance.Type,
    _ request: Any
  ) -> AsyncStream<[any Entity]> {
    observe((request as? Request<Instance>) ?? Request<Instance>.all)
      .compactMap { $0 as [any Entity] }
      .eraseToStream()
  }
}

extension CoreTransaction {
  fileprivate func fetch<Instance: Entity>(
    _: Instance.Type,
    _ request: Any
  ) async throws -> [Instance] {
    try await fetch((request as? Request<Instance>) ?? .all)
  }
}
