//
//  Live.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

@preconcurrency
import CoreData
import Dependencies
import Foundation
import XCTestDynamicOverlay

final class DatabaseClientLive: DatabaseClient {
    let pc: NSPersistentContainer

    init() {
        guard let databaseURL = Bundle.module.url(
            forResource: "mochi",
            withExtension: "momd"
        ) else {
            fatalError("Failed to find data model for mochi")
        }

        let database = databaseURL.deletingPathExtension().lastPathComponent

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: databaseURL) else {
            fatalError("Failed to create model from file: \(databaseURL)")
        }

        let pc = NSPersistentContainer(
            name: database,
            managedObjectModel: managedObjectModel
        )

        pc.loadPersistentStores { description, error in
            if let error {
                fatalError("Unable to load persistent stores: \(error)")
            }

            description.shouldMigrateStoreAutomatically = false
            description.shouldInferMappingModelAutomatically = true
            pc.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }
        self.pc = pc
    }

    func insert<T: MORepresentable>(_ item: T) async throws {
        try await pc.schedule { context in
            let object: NSManagedObject?

            if let objectFound = try context.fetch(.all.where(T.idKeyPath == item[keyPath: T.idKeyPath])).first {
                object = objectFound
            } else {
                object = context.insert(entity: T.entityName)
            }

            try object?.update(with: item)
        }
    }

    func update<T: MORepresentable, V: ConvertableValue>(
        _ id: T.EntityID,
        _ keyPath: WritableKeyPath<T, V?>,
        _ value: V?
    ) async throws -> Bool {
        try await pc.schedule { ctx in
            if let managed = try ctx.fetch(.all.where(T.idKeyPath == id)).first {
                try managed.update(keyPath, value)
                return true
            } else {
                return false
            }
        }
    }

    func update<T: MORepresentable, V: ConvertableValue>(
        _ id: T.EntityID,
        _ keyPath: WritableKeyPath<T, V>,
        _ value: V
    ) async throws -> Bool {
        try await pc.schedule { ctx in
            if let managed = try ctx.fetch(.all.where(T.idKeyPath == id)).first {
                try managed.update(keyPath, value)
                return true
            } else {
                return false
            }
        }
    }

    func delete<T: MORepresentable>(_ item: T) async throws {
        try await pc.schedule { ctx in
            try ctx.delete(.all.where(T.idKeyPath == item[keyPath: T.idKeyPath]))
        }
    }

    func fetch<T: MORepresentable>(_ request: Request<T>) async throws -> [T] {
        try await pc.schedule { context in
            try context.fetch(request).map { try $0.decode() }
        }
    }

    func observe<T: MORepresentable>(_ request: Request<T>) -> AsyncStream<[T]> {
        .init { continuation in
            let cancellation = Task.detached { [unowned self] in
                let values = try? await self.fetch(request)
                continuation.yield(values ?? [])

                for await _ in NotificationCenter.default.notifications(named: NSManagedObjectContext.didSaveObjectsNotification) {
                    let values = try? await self.fetch(request)
                    continuation.yield(values ?? [])
                }
            }

            continuation.onTermination = { _ in
                cancellation.cancel()
            }
        }
    }
}
