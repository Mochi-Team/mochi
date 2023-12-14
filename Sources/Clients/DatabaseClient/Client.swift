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

// MARK: - DatabaseClient

public struct DatabaseClient: Sendable {
  public var initialize: @Sendable () async throws -> Void
  public var insert: @Sendable (any Entity) async throws -> any Entity
  public var update: @Sendable (any Entity) async throws -> any Entity
  public var delete: @Sendable (any Entity) async throws -> Void
  var fetch: @Sendable (any Entity.Type, any _Request) async throws -> [any Entity]
  var observe: @Sendable (any Entity.Type, any _Request) -> AsyncStream<[any Entity]>
}

extension DatabaseClient {
  public func fetch<T: Entity>(_ request: Request<T>) async throws -> [T] {
    try await (fetch(T.self, request) as? [T]) ?? []
  }

  public func observe<T: Entity>(_ request: Request<T>) -> AsyncStream<[T]> {
    observe(T.self, request)
      .compactMap { ($0 as? [T]) ?? [] }
      .eraseToStream()
  }
}

// MARK: DatabaseClient.Error

extension DatabaseClient {
  public enum Error: Swift.Error {
    case managedContextNotAvailable
    case managedObjectIdIsTemporary
  }
}

// MARK: DependencyKey

extension DatabaseClient: DependencyKey {}

extension DependencyValues {
  public var databaseClient: DatabaseClient {
    get { self[DatabaseClient.self] }
    set { self[DatabaseClient.self] = newValue }
  }
}
