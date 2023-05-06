//
//  Client.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import CoreData
import Dependencies
import Foundation
import XCTestDynamicOverlay

public protocol DatabaseClient: Sendable {
    @Sendable
    func insert<T: MORepresentable>(_ item: T) async throws

    @Sendable
    @discardableResult
    func update<T: MORepresentable, V: ConvertableValue>(
        _ id: T.EntityID,
        _ keyPath: WritableKeyPath<T, V>,
        _ value: V
    ) async throws -> Bool

    @Sendable
    @discardableResult
    func update<T: MORepresentable, V: ConvertableValue>(
        _ id: T.EntityID,
        _ keyPath: WritableKeyPath<T, V?>,
        _ value: V?
    ) async throws -> Bool

    @Sendable
    func delete<T: MORepresentable>(_ item: T) async throws

    @Sendable
    func fetch<T: MORepresentable>(_ request: Request<T>) async throws -> [T]

    @Sendable
    func observe<T: MORepresentable>(_ request: Request<T>) -> AsyncStream<[T]>
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
