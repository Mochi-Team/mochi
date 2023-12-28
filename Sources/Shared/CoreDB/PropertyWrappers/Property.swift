//
//  Property.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

// MARK: - PropertyError

enum PropertyError: Error {
  case invalidPropertyType
  case encodingTypeInvalid
  case decodingTypeInvalid
}

// MARK: - OpaqueProperty

protocol OpaqueProperty {
  associatedtype WrappedValue
  var name: Box<String?> { get }
  var wrappedValue: WrappedValue { get set }
  var traits: Set<PropertyTrait> { get }
}

extension OpaqueProperty {
  var hasInitialized: Bool { name.value != nil }
  var isOptionalType: Bool { WrappedValue.self is any OpaqueOptional.Type }

  func asPropertyDescriptor() throws -> NSPropertyDescription {
    // if let value = self as? any OpaqueAttribute {
    //   return NSAttributeDescription(value)
    // } else if let value = self as? any OpaqueRelation {
    //   return NSRelationshipDescription(value)
    // } else {
    throw PropertyError.encodingTypeInvalid
    // }
  }
}

extension OpaqueProperty {
  /// Encodes a Property to NSManagedObject
  ///
  func encode(with _: NSManagedObjectID, context _: NSManagedObjectContext) throws {
    // if let attribute = self as? any OpaqueAttribute {
    //   try context.object(with: id).encode(attribute)
    // } else if let relation = self as? any OpaqueRelation {
    //   try context.object(with: id).encode(relation)
    // } else {
    throw PropertyError.invalidPropertyType
    // }
  }

  /// Decodes a property from NSManagedObject
  ///
  mutating func decode(from _: NSManagedObjectID, context _: NSManagedObjectContext) throws {
    // if let attribute = self as? (any OpaqueAttribute & OptionalWrappedValue) {
    //   wrappedValue = try cast(context.object(with: id).decode(attribute), to: WrappedValue.self)
    // } else if let attribute = self as? any OpaqueAttribute {
    //   wrappedValue = try cast(context.object(with: id).decode(attribute), to: WrappedValue.self)
    // } else if let relation = self as? any OpaqueRelation {
    //   wrappedValue = try cast(context.object(with: id).decode(relation), to: WrappedValue.self)
    // } else {
    throw PropertyError.decodingTypeInvalid
    // }
  }
}

// MARK: - PropertyTrait

public enum PropertyTrait {
  case transient
  case allowsCloudEncryption
  case allowsExternalBinaryDataStorage
  case preservesValueInHistoryOnDeletion
}

// MARK: - OptionalWrappedValue

protocol OptionalWrappedValue: OpaqueProperty where WrappedValue: OpaqueOptional {}

// MARK: - Attribute + OptionalWrappedValue

extension Attribute: OptionalWrappedValue where WrappedValue: OpaqueOptional {}

// MARK: - Relation + OptionalWrappedValue

extension Relation: OptionalWrappedValue where WrappedValue: OpaqueOptional {}
