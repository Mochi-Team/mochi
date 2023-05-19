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

public protocol DatabaseClient: Sendable {
    @Sendable
    func initialize() async throws

    @Sendable
    func insert<T: Entity>(_ item: T) async throws

    @Sendable
    func insertOrUpdate<T: Entity>(_ item: T) async throws

    @Sendable
    @discardableResult
    func update<T: Entity>(_ item: T) async throws -> Bool

    @Sendable
    func delete<T: Entity>(_ item: T) async throws

    @Sendable
    func fetch<T: Entity>(_ request: Request<T>) async throws -> [T]

    @Sendable
    func observe<T: Entity>(_ request: Request<T>) -> AsyncStream<[T]>
}

public struct DatabaseClientKey: DependencyKey {
    public static let liveValue: any DatabaseClient = DatabaseClientLive()
}

extension DependencyValues {
    public var databaseClient: any DatabaseClient {
        get { self[DatabaseClientKey.self] }
        set { self[DatabaseClientKey.self] = newValue }
    }
}
