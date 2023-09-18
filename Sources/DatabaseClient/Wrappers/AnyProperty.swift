//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

public struct AnyProperty<E: Entity>: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public static func == (lhs: AnyProperty<E>, rhs: AnyProperty<E>) -> Bool {
        lhs.name == rhs.name
    }

    let name: String

    let encode: () -> Void = { }
    let decode: () -> Void = { }

    public init<Value: TransformableValue>(
        _ name: String,
        _ keyPath: WritableKeyPath<E, Value>
    ) {
        self.name = name
    }
}

// MARK: - PropertyError

enum PropertyError: Error {
    case invalidPropertyType
    case encodingTypeInvalid
    case decodingTypeInvalid
}

// MARK: - OpaqueProperty

protocol OpaqueProperty {
    associatedtype EnclosingEntity: Entity
    associatedtype WrappedValue
    var name: String { get }
    var wrappedValue: WrappedValue { get set }
    var objectID: NSManagedObjectID? { get set }
    var keyPath: PartialKeyPath<EnclosingEntity> { get }
}

extension OpaqueProperty {
    var isOptionalType: Bool { WrappedValue.self is any OpaqueOptional.Type }
}

extension OpaqueProperty {
    /// Encodes a Property to NSManagedObject
    ///
    func encode(with id: NSManagedObjectID, context: NSManagedObjectContext) throws {
        if let attribute = self as? any OpaqueAttribute {
            try context.object(with: id).encode(attribute)
        } else if let relation = self as? any OpaqueRelation {
            try context.object(with: id).encode(relation)
        } else {
            throw PropertyError.invalidPropertyType
        }
    }

    /// Decodes a property from NSManagedObject
    ///
    mutating func decode(from id: NSManagedObjectID, context: NSManagedObjectContext) throws {
        if let attribute = self as? (any OpaqueAttribute & OptionalWrappedValue) {
            wrappedValue = try cast(context.object(with: id).decode(attribute), to: WrappedValue.self)
        } else if let attribute = self as? any OpaqueAttribute {
            wrappedValue = try cast(context.object(with: id).decode(attribute), to: WrappedValue.self)
        } else if let relation = self as? any OpaqueRelation {
            wrappedValue = try cast(context.object(with: id).decode(relation), to: WrappedValue.self)
        } else {
            throw PropertyError.decodingTypeInvalid
        }
    }
}

// MARK: - PropertyTrait

public enum PropertyTrait {
    case transient
    case allowsCloudEncryption
    case allowsExternalBinaryDataStorage
    case preservesValueInHistoryOnDeletion
}

protocol OptionalWrappedValue: OpaqueProperty where WrappedValue: OpaqueOptional {}
extension AnyAttribute: OptionalWrappedValue where WrappedValue: OpaqueOptional {}
extension AnyRelation: OptionalWrappedValue where WrappedValue: OpaqueOptional {}

extension OpaqueProperty {
    mutating func update(with instance: EnclosingEntity, id: NSManagedObjectID, context: NSManagedObjectContext) {
    }

    func lol() {}
}
