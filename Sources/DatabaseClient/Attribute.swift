//
//  Attrribute.swift
//  
//
//  Created by ErrorErrorError on 5/3/23.
//  
//

import CoreData
import Foundation

public struct Attribute<PlainObject: MORepresentable>: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    var isRelation = false
    let name: String
    let keyPath: PartialKeyPath<PlainObject>
    let encode: (PlainObject, NSManagedObject) throws -> Void
    let decode: (inout PlainObject, NSManagedObject) throws -> Void
}

extension Attribute {
    public init<Value: ConvertableValue>(
        _ name: String,
        _ keyPath: WritableKeyPath<PlainObject, Value>
    ) {
        self.name = name
        self.encode = { plainObject, managedObject in
            managedObject[primitiveValue: name] = plainObject[keyPath: keyPath].encode()
        }
        self.decode = { plainObject, managedObject in
            do {
                plainObject[keyPath: keyPath] = try Value.decode(managedObject[primitiveValue: name])
            } catch {
                throw AttributeError.failedToDecode(for: name, model: PlainObject.entityName)
            }
        }
        self.keyPath = keyPath
    }

    // MARK: Optional Primitive Attribute

    public init<Value: ConvertableValue>(
        _ name: String,
        _ keyPath: WritableKeyPath<PlainObject, Value?>
    ) {
        self.name = name
        self.encode = { plainObject, managedObject in
            managedObject[primitiveValue: name] = plainObject[keyPath: keyPath]?.encode()
        }
        self.decode = { plainObject, managedObject in
            do {
                plainObject[keyPath: keyPath] = try Value?.decode(managedObject[primitiveValue: name])
            } catch {
                throw AttributeError.failedToDecode(for: name, model: PlainObject.entityName)
            }
        }
        self.keyPath = keyPath
    }

    // MARK: To One

    public init<Relation: MORepresentable>(
        _ name: String,
        _ keyPath: WritableKeyPath<PlainObject, Relation>
    ) {
        self.name = name
        self.encode = { plainObject, managedObject in
            try plainObject[keyPath: keyPath].encodeAttributes(to: managedObject)
        }
        self.decode = { plainObject, managedObject in
            guard let object = managedObject.value(forKey: name) as? NSManagedObject else {
                throw AttributeError.failedToDecode(for: name, model: PlainObject.entityName)
            }

            plainObject[keyPath: keyPath] = try Relation(from: object)
        }
        self.keyPath = keyPath
        self.isRelation = true
    }

    // MARK: To Many

    public init<Relation: MORepresentable>(
        _ name: String,
        _ keyPath: WritableKeyPath<PlainObject, Set<Relation>>
    ) {
        self.name = name
        self.encode = { plainObject, managedObject in
            let managedObjects = managedObject.mutableSetValue(forKey: name)
            let objects = plainObject[keyPath: keyPath]

            // Adding and updating existing elements
            for object in objects {
                var managed = try managedObjects.compactMap { $0 as? NSManagedObject }
                    .first { try Relation(from: $0)[keyPath: Relation.idKeyPath] == object[keyPath: Relation.idKeyPath] }

                if managed == nil {
                    managed = try managedObject.managedObjectContext?
                        .fetch(.all.where(Relation.idKeyPath == object[keyPath: Relation.idKeyPath])).first
                }

                if managed == nil {
                    managed = managedObject.managedObjectContext?.insert(entity: Relation.entityName)
                }

                guard let managed else {
                    throw AttributeError.failedToEncodeRelation(for: name, model: PlainObject.entityName)
                }

                managedObjects.add(managed)
                try managed.update(with: object)
            }

            // Remove elements not in array
            let copiedManagedObjects = (managedObjects.copy() as? NSSet)?
                .compactMap { $0 as? NSManagedObject } ?? .init()

            for managed in copiedManagedObjects {
                guard let wrapped = try? Relation(from: managed) else {
                    continue
                }

                if !objects
                    .contains(where: { wrapped[keyPath: Relation.idKeyPath] == $0[keyPath: Relation.idKeyPath] }) {
                    managedObjects.remove(managed)
                }
            }
        }
        self.decode = { plainObject, managedObject in
            guard let objects = managedObject.value(forKey: name) as? NSSet as? Set<NSManagedObject> else {
                throw AttributeError.failedToDecode(for: name, model: PlainObject.entityName)
            }

            plainObject[keyPath: keyPath] = try Set(objects.compactMap { try Relation(from: $0) })
        }
        self.keyPath = keyPath
        self.isRelation = true
    }

    // MARK: To Many Ordered

    public init<Relation: MORepresentable>(
        _ name: String,
        _ keyPath: WritableKeyPath<PlainObject, [Relation]>
    ) {
        self.name = name
        self.encode = { plainObject, managedObject in
            let managedObjects = managedObject.mutableOrderedSetValue(forKey: name)
            let objects = plainObject[keyPath: keyPath]

            // Adding and updating existing elements
            for (index, object) in objects.enumerated() {
                var managed = try managedObjects.compactMap { $0 as? NSManagedObject }
                    .first { try Relation(from: $0)[keyPath: Relation.idKeyPath] == object[keyPath: Relation.idKeyPath] }

                if managed == nil {
                    managed = try managedObject.managedObjectContext?
                        .fetch(.all.where(Relation.idKeyPath == object[keyPath: Relation.idKeyPath])).first
                }

                if managed == nil {
                    managed = managedObject.managedObjectContext?.insert(entity: Relation.entityName)
                }

                guard let managed else {
                    throw AttributeError.failedToEncodeRelation(for: name, model: PlainObject.entityName)
                }

                if managedObjects.contains(managed) {
                    managedObjects.remove(managed)
                }

                managedObjects.insert(managed, at: index)

                try managed.update(with: object)
            }

            // Remove elements not in array
            let copiedManagedObjects = (managedObjects.copy() as? NSOrderedSet)?
                .compactMap { $0 as? NSManagedObject } ?? .init()

            for managed in copiedManagedObjects {
                guard let wrapped = try? Relation(from: managed) else {
                    continue
                }

                if !objects
                    .contains(where: { wrapped[keyPath: Relation.idKeyPath] == $0[keyPath: Relation.idKeyPath] }) {
                    managedObjects.remove(managed)
                }
            }
        }
        self.decode = { plainObject, managedObject in
            guard let objects = managedObject.value(forKey: name) as? NSOrderedSet else {
                throw AttributeError.failedToDecode(for: name, model: PlainObject.entityName)
            }

            plainObject[keyPath: keyPath] = try Array(
                objects.compactMap { $0 as? NSManagedObject }
                    .compactMap { try Relation(from: $0) }
            )
        }
        self.keyPath = keyPath
        self.isRelation = true
    }
}

// MARK: - AttributeError

enum AttributeError: Swift.Error {
    case failedToDecode(for: String, model: String)
    case failedToEncode(for: String, model: String)
    case failedToEncodeRelation(for: String, model: String)
    case badInput(Any?)
}

// MARK: - PrimitiveType

public protocol PrimitiveType {}

// MARK: - ConvertableValue

public protocol ConvertableValue {
    associatedtype ValueType: PrimitiveType
    func encode() -> ValueType
    static func decode(value: ValueType) throws -> Self
}

public extension ConvertableValue where Self: PrimitiveType {
    func encode() -> Self { self }
    static func decode(value: Self) throws -> Self { value }
}

extension ConvertableValue {
    static func decode(_ some: Any?) throws -> Self {
        guard let value = some as? Self.ValueType else {
            throw AttributeError.badInput(some)
        }
        return try Self.decode(value: value)
    }
}

extension Optional where Wrapped: ConvertableValue {
    static func decode(_ anyValue: Any?) throws -> Wrapped? {
        try anyValue.flatMap { value in
            try Wrapped.decode(value)
        }
    }
}

public extension RawRepresentable where RawValue: ConvertableValue {
    func encode() -> RawValue.ValueType {
        rawValue.encode()
    }

    static func decode(value: RawValue.ValueType) throws -> Self {
        let rawValue = try RawValue.decode(value: value)
        guard let value = Self(rawValue: rawValue) else {
            throw AttributeError.badInput(rawValue)
        }
        return value
    }
}

// MARK: - Int + PrimitiveType, ConvertableValue

extension Int: PrimitiveType, ConvertableValue {}

// MARK: - Int16 + PrimitiveType, ConvertableValue

extension Int16: PrimitiveType, ConvertableValue {}

// MARK: - Int32 + PrimitiveType, ConvertableValue

extension Int32: PrimitiveType, ConvertableValue {}

// MARK: - Int64 + PrimitiveType, ConvertableValue

extension Int64: PrimitiveType, ConvertableValue {}

// MARK: - Float + PrimitiveType, ConvertableValue

extension Float: PrimitiveType, ConvertableValue {}

// MARK: - Double + PrimitiveType, ConvertableValue

extension Double: PrimitiveType, ConvertableValue {}

// MARK: - Decimal + PrimitiveType, ConvertableValue

extension Decimal: PrimitiveType, ConvertableValue {}

// MARK: - Bool + PrimitiveType, ConvertableValue

extension Bool: PrimitiveType, ConvertableValue {}

// MARK: - Date + PrimitiveType, ConvertableValue

extension Date: PrimitiveType, ConvertableValue {}

// MARK: - String + PrimitiveType, ConvertableValue

extension String: PrimitiveType, ConvertableValue {}

// MARK: - Data + PrimitiveType, ConvertableValue

extension Data: PrimitiveType, ConvertableValue {}

// MARK: - UUID + PrimitiveType, ConvertableValue

extension UUID: PrimitiveType, ConvertableValue {}

// MARK: - URL + PrimitiveType, ConvertableValue

extension URL: PrimitiveType, ConvertableValue {}
