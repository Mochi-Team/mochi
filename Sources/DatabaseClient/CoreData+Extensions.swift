//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/3/23.
//  
//

import CoreData
import Foundation

extension NSPersistentContainer {
    func schedule<T>(
        _ action: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try Task.checkCancellation()

        let context = newBackgroundContext()
        return try await context.perform(schedule: .immediate) {
            try context.execute(action)
        }
    }
}

extension NSManagedObjectContext {
    func insert(entity name: String) -> NSManagedObject? {
        persistentStoreCoordinator
            .flatMap { $0.managedObjectModel.entitiesByName[name] }
            .flatMap { .init(entity: $0, insertInto: self) }
    }

    func fetch<T: MORepresentable>(_ request: Request<T>) throws -> [NSManagedObject] {
        try fetch(request.makeFetchRequest())
    }

    func delete(_ request: Request<some MORepresentable>) throws {
        let items = try fetch(request)

        for item in items {
            delete(item)
        }
    }

    func execute<T>(
        _ callback: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) throws -> T {
        defer {
            self.reset()
        }

        let value = try callback(self)

        if hasChanges {
            try save()
        }

        return value
    }
}

extension NSManagedObject {
    func decode<T: MORepresentable>() throws -> T {
        var value = T.createEmptyValue()
        try T.attributes.forEach { attribute in
            try attribute.decode(&value, self)
        }
        return value
    }

    func update(with item: some MORepresentable) throws {
        try item.encodeAttributes(to: self)
    }

    func update<T: MORepresentable, V: ConvertableValue>(
        _ keyPath: WritableKeyPath<T, V>,
        _ value: V
    ) throws {
        self[primitiveValue: T.attribute(keyPath).name] = value.encode()
    }

    func update<T: MORepresentable, V: ConvertableValue>(
        _ keyPath: WritableKeyPath<T, V?>,
        _ value: V?
    ) throws {
        self[primitiveValue: T.attribute(keyPath).name] = value?.encode()
    }

    subscript(primitiveValue forKey: String) -> Any? {
        get {
            defer { didAccessValue(forKey: forKey) }
            willAccessValue(forKey: forKey)
            return primitiveValue(forKey: forKey)
        }
        set(newValue) {
            defer { didChangeValue(forKey: forKey) }
            willChangeValue(forKey: forKey)
            setPrimitiveValue(newValue, forKey: forKey)
        }
    }
}
