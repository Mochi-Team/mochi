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

        if let optional = attribute.wrappedValue as? OpaqueOptional {
            self[primitiveValue: key] = optional.isNil ? nil : try attribute.wrappedValue.encode()
        } else {
            self[primitiveValue: key] = try attribute.wrappedValue.encode()
        }
    }

    func encode<R: OpaqueRelation>(_ relation: R) throws {
        guard let key = relation.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: relation.name.value ?? "Unknown")
        }

        switch relation.relationType {
        case .toOne:
            try encodeToOne(relation.wrappedValue as? R.DestinationEntity, forKey: key)
        case .toMany:
            if !relation.isOrdered {
                try encodeToManyUnordered(
                    R.DestinationEntity.self,
                    relation.wrappedValue as? Set<AnyHashable>,
                    forKey: key
                )
            } else {
                try encodeToManyOrdered(
                    relation.wrappedValue as? [R.DestinationEntity],
                    forKey: key
                )
            }
        }
    }

    func encodeToOne<DestinationEntity: OpaqueEntity>(_ entity: DestinationEntity?, forKey key: String) throws {
        guard let managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        defer { didChangeValue(forKey: key) }

        guard let entity else {
            setValue(nil, forKey: key)
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
            setValue(managedObject, forKey: key)
        }
    }

    func encodeToManyOrdered<DestinationEntity: OpaqueEntity>(_ array: [DestinationEntity]?, forKey key: String) throws {
        guard let managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        defer { didChangeValue(forKey: key) }

        guard let array else {
            setValue(nil, forKey: key)
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

        setValue(cocoaArray, forKey: key)
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
            setValue(nil, forKey: key)
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

        setValue(cocoaSet, forKey: key)
    }

    func decode<A: OpaqueAttribute>(_ attribute: A) throws -> A.WrappedValue? where A.WrappedValue: OpaqueOptional {
        guard let key = attribute.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: attribute.name.value ?? "Unknown")
        }

        return try (self[primitiveValue: key] as? A.WrappedValue.Primitive)
            .flatMap { try A.WrappedValue.decode(value: $0) }
    }

    func decode<A: OpaqueAttribute>(_ attribute: A) throws -> A.WrappedValue {
        guard let key = attribute.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: attribute.name.value ?? "Unknown")
        }

        guard let primitiveValue = self[primitiveValue: key] as? A.WrappedValue.Primitive else {
            throw Error.castError
        }
        return try A.WrappedValue.decode(value: primitiveValue)
    }

    func decode<R: OpaqueRelation>(_ relation: R) throws -> R.WrappedValue {
        guard let key = relation.name.value, entity.propertiesByName[key] != nil else {
            throw Error.propertyNotAvailable(forEntity: entity.name ?? "Unknown Entity Name", key: relation.name.value ?? "Unknown")
        }

        switch relation.relationType {
        case .toOne:
            return try cast(decodeToOne(R.DestinationEntity.self, forKey: key), to: R.WrappedValue.self)
        case .toMany:
            if relation.isOrdered {
                return try cast(
                    decodeToManyOrdered(
                        R.DestinationEntity.self,
                        forKey: key
                    ),
                    to: R.WrappedValue.self
                )
            } else {
                return try cast(
                    decodeToManyUnordered(
                        R.DestinationEntity.self,
                        forKey: key
                    ),
                    to: R.WrappedValue.self
                )
            }
        }
    }

    func decodeToOne<SomeEntity: OpaqueEntity>(_: SomeEntity.Type, forKey: String) throws -> SomeEntity? {
        guard let managedObjectContext else {
            throw Error.contextIsNotAvailable
        }

        let managed = try? cast(value(forKey: forKey), to: NSManagedObject.self)
        return try managed.flatMap { try .init(unmanagedId: $0.objectID, context: managedObjectContext) }
    }

    func decodeToManyOrdered<SomeEntity: OpaqueEntity>(
        _: SomeEntity.Type,
        forKey key: String
    ) throws -> [SomeEntity]? {
        guard let managedObjectContext else {
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
        guard let managedObjectContext else {
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
}
