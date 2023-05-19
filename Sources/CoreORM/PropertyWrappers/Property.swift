//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/15/23.
//  
//

import CoreData
import Foundation

enum PropertyError: Error {
    case invalidPropertyType
}

protocol OpaqueProperty {
    associatedtype WrappedValue
    var name: Box<String?> { get }
    var wrappedValue: WrappedValue { get set }
    var traits: [PropertyTrait] { get }

    var internalValue: Box<WrappedValue> { get }
    var managedObjectId: Box<NSManagedObjectID?> { get }
}

extension OpaqueProperty {
    var hasInitialized: Bool { name.value != nil }
    var isOptional: Bool { WrappedValue.self is any _OptionalType.Type }

    func asPropertyDescriptor() throws -> NSPropertyDescription {
        if let value = self as? any OpaqueAttribute {
            return NSAttributeDescription(value)
        } else if let value = self as? any OpaqueRelation {
            return NSRelationshipDescription(value)
        } else {
            throw PropertyError.invalidPropertyType
        }
    }
}

extension OpaqueProperty {

    /// Encodes a Property to NSManagedObject
    ///
    func encode(with id: NSManagedObjectID, context: NSManagedObjectContext) throws {
        if let attribute = self as? any OpaqueAttribute {
            try context.object(with: id).encode(attribute)
        } else if let relation = self as? any OpaqueRelation {
            try context.object(with: id).encode(relation)
        }
    }

    /// Decodes a property from NSManagedObject
    ///
    func decode(from id: NSManagedObjectID, context: NSManagedObjectContext) throws {
        if let attribute = self as? any OpaqueAttribute {
            self.internalValue.value = try cast(try context.object(with: id).decode(attribute), to: WrappedValue.self)
        } else if let relation = self as? any OpaqueRelation {
            self.internalValue.value = try cast(try context.object(with: id).decode(relation), to: WrappedValue.self)
        }
    }
}

public enum PropertyTrait {
    case transient
    case allowsCloudEncryption
    case allowsExternalBinaryDataStorage
    case preservesValueInHistoryOnDeletion
}
