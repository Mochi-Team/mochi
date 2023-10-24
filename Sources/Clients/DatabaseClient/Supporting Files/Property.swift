//
//  Property.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

// MARK: - Property

public struct Property<E: Entity> {
    let name: String
    let keyPath: AnyKeyPath
    let encode: (E, NSManagedObject) throws -> Void
    let decode: (inout E, NSManagedObject) throws -> Void
    var isRelation = true
}

// MARK: Hashable

extension Property: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public static func == (lhs: Property<E>, rhs: Property<E>) -> Bool {
        lhs.name == rhs.name
    }
}

extension Property {
    static func verifyObjectNameAvailable(_ name: String, _ object: NSManagedObject) throws {
        guard object.entity.propertiesByName[name] != nil else {
            throw Error.propertyNotAvailable(forEntity: object.entity.name ?? "Unknown", key: name)
        }
    }
}

// Attributes - TransformableValue

public extension Property {
    init<Value: TransformableValue>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, Value?>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)
            object[primitiveValue: name] = try instance[keyPath: keyPath]?.encode()
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            instance[keyPath: keyPath] = try Value.decode(object[primitiveValue: name])
        }
        self.keyPath = keyPath
        self.isRelation = false
    }

    init<Value: TransformableValue>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, Value>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)
            object[primitiveValue: name] = try instance[keyPath: keyPath].encode()
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            instance[keyPath: keyPath] = try Value.decode(object[primitiveValue: name])
        }
        self.keyPath = keyPath
        self.isRelation = false
    }
}

// Relations

public extension Property {
    /// This represents an optional to one relationship
    ///
    init<DestinationEntity: Entity>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, DestinationEntity?>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            let entity = instance[keyPath: keyPath]

            defer { object.didChangeValue(forKey: name) }

            object.willChangeValue(forKey: name)

            guard let entity else {
                object.setValue(nil, forKey: name)
                return
            }

            if let entityManagedObjectId = entity.objectID?.id {
                try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
            } else {
                let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                    forEntityName: DestinationEntity.entityName,
                    into: managedObjectContext
                )
                try entity.copy(to: managedObject.objectID, context: managedObjectContext)
                object.setValue(managedObject, forKey: name)
            }
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            let managed = try? cast(object.value(forKey: name), to: NSManagedObject.self)

            instance[keyPath: keyPath] = try managed.flatMap { try .init(id: $0.objectID, context: managedObjectContext) }
        }
        self.keyPath = keyPath
    }

    /// This represents to one relationship
    ///
    init<DestinationEntity: Entity>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, DestinationEntity>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            let entity = instance[keyPath: keyPath]

            defer { object.didChangeValue(forKey: name) }

            object.willChangeValue(forKey: name)

            if let entityManagedObjectId = entity.objectID?.id {
                try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
            } else {
                let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                    forEntityName: DestinationEntity.entityName,
                    into: managedObjectContext
                )
                try entity.copy(to: managedObject.objectID, context: managedObjectContext)
                object.setValue(managedObject, forKey: name)
            }
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            let managed = try cast(object.value(forKey: name), to: NSManagedObject.self)

            instance[keyPath: keyPath] = try .init(id: managed.objectID, context: managedObjectContext)
        }
        self.keyPath = keyPath
    }

    /// This represents an optional to-many relationship set
    ///
    init<DestinationEntity: Entity>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, Set<DestinationEntity>?>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            defer { object.didChangeValue(forKey: name) }

            let set = instance[keyPath: keyPath]

            guard let set else {
                object.setValue(nil, forKey: name)
                return
            }

            let cocoaSet = NSMutableSet()

            try set.forEach { entity in
                if let entityManagedObjectId = entity.objectID?.id {
                    try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
                    cocoaSet.add(managedObjectContext.object(with: entityManagedObjectId))
                } else {
                    let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                        forEntityName: DestinationEntity.entityName,
                        into: managedObjectContext
                    )
                    try entity.copy(to: managedObject.objectID, context: managedObjectContext)
                    cocoaSet.add(managedObject)
                }
            }

            object.setValue(cocoaSet, forKey: name)
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            instance[keyPath: keyPath] = try Set(
                object.mutableSetValue(forKey: name).compactMap { element in
                    try DestinationEntity(
                        unmanagedId: cast(element, to: NSManagedObject.self).objectID,
                        context: managedObjectContext
                    )
                }
            )
        }
        self.keyPath = keyPath
    }

    /// This represents to-many relationship set
    ///
    init<DestinationEntity: Entity>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, Set<DestinationEntity>>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            defer { object.didChangeValue(forKey: name) }

            let cocoaSet = NSMutableSet()

            try instance[keyPath: keyPath].forEach { entity in
                if let entityManagedObjectId = entity.objectID?.id {
                    try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
                    cocoaSet.add(managedObjectContext.object(with: entityManagedObjectId))
                } else {
                    let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                        forEntityName: DestinationEntity.entityName,
                        into: managedObjectContext
                    )
                    try entity.copy(to: managedObject.objectID, context: managedObjectContext)
                    cocoaSet.add(managedObject)
                }
            }

            object.setValue(cocoaSet, forKey: name)
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            instance[keyPath: keyPath] = try Set(
                object.mutableSetValue(forKey: name).compactMap { element in
                    try DestinationEntity(
                        unmanagedId: cast(element, to: NSManagedObject.self).objectID,
                        context: managedObjectContext
                    )
                }
            )
        }
        self.keyPath = keyPath
    }

    /// This represents an optional to-many relationship ordered array
    ///
    init<DestinationEntity: Entity>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, [DestinationEntity]?>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            defer { object.didChangeValue(forKey: name) }

            guard let array = instance[keyPath: keyPath] else {
                object.setValue(nil, forKey: name)
                return
            }

            let cocoaArray = NSMutableArray()

            try array.forEach { entity in
                if let entityManagedObjectId = entity.objectID?.id {
                    try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
                    cocoaArray.add(managedObjectContext.object(with: entityManagedObjectId))
                } else {
                    let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                        forEntityName: DestinationEntity.entityName,
                        into: managedObjectContext
                    )
                    try entity.copy(to: managedObject.objectID, context: managedObjectContext)
                    cocoaArray.add(managedObject)
                }
            }

            object.setValue(cocoaArray, forKey: name)
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            instance[keyPath: keyPath] = try object.mutableOrderedSetValue(forKey: name).map { element in
                try DestinationEntity(
                    unmanagedId: cast(element, to: NSManagedObject.self).objectID,
                    context: managedObjectContext
                )
            }
        }
        self.keyPath = keyPath
    }

    /// This represents to-many relationship ordered array
    ///
    init<DestinationEntity: Entity>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, [DestinationEntity]>
    ) {
        self.name = name
        self.encode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            defer { object.didChangeValue(forKey: name) }

            let cocoaArray = NSMutableArray()

            try instance[keyPath: keyPath].forEach { entity in
                if let entityManagedObjectId = entity.objectID?.id {
                    try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
                    cocoaArray.add(managedObjectContext.object(with: entityManagedObjectId))
                } else {
                    let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                        forEntityName: DestinationEntity.entityName,
                        into: managedObjectContext
                    )
                    try entity.copy(to: managedObject.objectID, context: managedObjectContext)
                    cocoaArray.add(managedObject)
                }
            }

            object.setValue(cocoaArray, forKey: name)
        }
        self.decode = { instance, object in
            try Self.verifyObjectNameAvailable(name, object)

            guard let managedObjectContext = object.managedObjectContext else {
                throw Error.contextIsNotAvailable
            }

            instance[keyPath: keyPath] = try object.mutableOrderedSetValue(forKey: name).map { element in
                try DestinationEntity(
                    unmanagedId: cast(element, to: NSManagedObject.self).objectID,
                    context: managedObjectContext
                )
            }
        }
        self.keyPath = keyPath
    }
}

// MARK: Property.Error

extension Property {
    enum Error: Swift.Error {
        case propertyNotAvailable(forEntity: String, key: String)
        case contextIsNotAvailable
    }
}
