//
//  NSManagedObject.swift
//  
//
//  Created by ErrorErrorError on 5/15/23.
//  
//

import CoreData
import Foundation

extension NSManagedObject {
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

extension NSManagedObject {
    public enum Error: Swift.Error {
        case propertyNotAvailable(forEntity: String, key: String)
        case invalidValueEncodingType
        case invalidPrimitiveValueDecoding
        case castError
        case dataIsAtFault(for: String)
        case contextIsNotAvailable
        case propertyValueNilWhenValueIsRequired
    }

    func encode<A: OpaqueAttribute>(_ attribute: A) throws {
        guard let key = attribute.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: attribute.name.value ?? "Unknown")
        }

        self.encode(attribute.wrappedValue as? A.Value, forKey: key)
    }

    func encode<R: OpaqueRelation>(_ relation: R) throws {
        guard let key = relation.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: relation.name.value ?? "Unknown")
        }

        switch relation.relationType {
        case .toOne:
            try self.encodeToOne(relation.wrappedValue as? R.DestinationEntity, forKey: key)
        case .toMany:
            if !relation.isOrdered {
                try self.encodeToManyUnordered(
                    R.DestinationEntity.self,
                    relation.wrappedValue as? Set<AnyHashable>,
                    forKey: key
                )
            } else {
                try self.encodeToManyOrdered(
                    relation.wrappedValue as? [R.DestinationEntity],
                    forKey: key
                )
            }
        }
    }

    func encode(_ value: (any TransformableValue)?, forKey key: String) {
        self[primitiveValue: key] = value?.encode()
    }

    func encodeToOne<DestinationEntity: OpaqueEntity>(_ entity: DestinationEntity?, forKey key: String) throws {
        guard let managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        defer { didChangeValue(forKey: key) }

        guard let entity else {
            self.setValue(nil, forKey: key)
            return
        }

        if let entityManagedObjectId = entity.mainManagedObjectId {
            try entity.copy(to: entityManagedObjectId, context: managedObjectContext)
            willChangeValue(forKey: key)
       } else {
            let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
                forEntityName: DestinationEntity.entityName,
                into: managedObjectContext
            )
            try entity.copy(to: managedObject.objectID, context: managedObjectContext)
            willChangeValue(forKey: key)
            self.setValue(managedObject, forKey: key)
        }
    }

    func encodeToManyOrdered<DestinationEntity: OpaqueEntity>(_ array: [DestinationEntity]?, forKey key: String) throws {
        guard let managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        defer { didChangeValue(forKey: key) }

        guard let array else {
            self.setValue(nil, forKey: key)
            return
        }

        let cocoaArray = NSMutableArray()

        try array.forEach { entity in
            if let entityManagedObjectId = entity.mainManagedObjectId {
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

        self.setValue(cocoaArray, forKey: key)
    }

    func encodeToManyUnordered<DestinationEntity: OpaqueEntity>(
        _: DestinationEntity.Type,
        _ set: Set<AnyHashable>?,
        forKey key: String
    ) throws {
        guard let managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        defer { didChangeValue(forKey: key) }

        guard let set else {
            self.setValue(nil, forKey: key)
            return
        }

        let cocoaSet = NSMutableSet()

        try set.compactMap { $0 as? DestinationEntity }.forEach { entity in
            if let entityManagedObjectId = entity.mainManagedObjectId {
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

        self.setValue(cocoaSet, forKey: key)
    }

    func decode<A: OpaqueAttribute>(_ attribute: A) throws -> A.WrappedValue {
        guard let key = attribute.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: attribute.name.value ?? "Unknown")
        }

        return try cast(try self.decode(A.Value.self, forKey: key), to: A.WrappedValue.self)
    }

    func decode<R: OpaqueRelation>(_ relation: R) throws -> R.WrappedValue {
        guard let key = relation.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: relation.name.value ?? "Unknown")
        }

        switch relation.relationType {
        case .toOne:
            return try cast(try self.decodeToOne(R.DestinationEntity.self, forKey: key), to: R.WrappedValue.self)
        case .toMany:
            if relation.isOrdered {
                return try cast(try self.decodeToManyOrdered(R.DestinationEntity.self, forKey: key), to: R.WrappedValue.self)
            } else {
                return try cast(
                    try self.decodeToManyUnordered(
                        R.DestinationEntity.self,
                        forKey: key
                    ),
                    to: R.WrappedValue.self
                )
            }
        }
    }

    func decode<T: TransformableValue>(_: T.Type, forKey key: String) throws -> T? {
        try? T.decode(self[primitiveValue: key])
    }

    func decodeToOne<SomeEntity: OpaqueEntity>(_ entityType: SomeEntity.Type, forKey: String) throws -> SomeEntity? {
        guard let managedObjectContext = managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        let managed = try? cast(value(forKey: forKey), to: NSManagedObject.self)
        return try managed.flatMap { try .init(unmanagedId: $0.objectID, context: managedObjectContext) }
    }

    func decodeToManyOrdered<SomeEntity: OpaqueEntity>(
        _: SomeEntity.Type,
        forKey key: String
    ) throws -> [SomeEntity]? {
        guard let managedObjectContext = managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        return try mutableSetValue(forKey: key).map { element in
            try SomeEntity(
                unmanagedId: cast(element, to: NSManagedObject.self).objectID,
                context: managedObjectContext
            )
        }
    }

    func decodeToManyUnordered<SomeEntity: OpaqueEntity>(
        _: SomeEntity.Type,
        forKey key: String
    ) throws -> Set<AnyHashable>? {
        guard let managedObjectContext = managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        return try Set(
            mutableSetValue(forKey: key).compactMap { element in
                try SomeEntity(
                    unmanagedId: cast(element, to: NSManagedObject.self).objectID,
                    context: managedObjectContext
                ) as? AnyHashable
            }
        )
    }

    func containsValue(forKey name: String?) -> Bool {
        name.flatMap { self.primitiveValue(forKey: $0) } != nil
    }
}
