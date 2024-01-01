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
  case propertyTypeInvalid
  case decodingTypeInvalid
}

// MARK: - AnyProperty

public struct AnyProperty<Model: Entity>: Hashable {
  let name: String
  let property: any OpaqueProperty

  var propertyName: String { property.name ?? name }
  var isRelation: Bool { property is any OpaqueRelation }

  public init<P: OpaqueProperty>(
    name: String,
    _ property: P
  ) where Model == P.Model {
    self.name = name
    self.property = property
  }

  func asPropertyDescriptor() throws -> NSPropertyDescription {
    if let property = property as? any OpaqueAttribute {
      return NSAttributeDescription(name, property)
    } else if let property = property as? any OpaqueRelation {
      return NSRelationshipDescription(name, property)
    }
    throw PropertyError.propertyTypeInvalid
  }

  func decode(_ model: inout Model, _ object: NSManagedObject) throws {
    if let transformable = property as? any TransformableProperty {
      func internalDecode<T: TransformableProperty>(_ value: T) throws {
        var modified = unsafeBitCast(model, to: T.Model.self)
        try value.decode(name, &modified, object)
        model = unsafeBitCast(modified, to: Model.self)
      }

      try internalDecode(transformable)
    }
  }

  func encode(_ model: Model, _ object: NSManagedObject) throws {
    if let transformable = property as? any TransformableProperty {
      func internalEncode<T: TransformableProperty>(_ value: T) throws {
        try value.encode(name, unsafeBitCast(model, to: T.Model.self), object)
      }

      try internalEncode(transformable)
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(property.name)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.name == rhs.name &&
      lhs.property.name == rhs.property.name
  }
}

// MARK: - OpaqueProperty

public protocol OpaqueProperty {
  associatedtype Model: Entity
  associatedtype Value
  var name: String? { get }
  var keyPath: WritableKeyPath<Model, Value> { get }
  var traits: Set<PropertyTrait> { get }
}

extension OpaqueProperty {
  var keyPath: AnyKeyPath { keyPath as AnyKeyPath }
  var isOptionalType: Bool { Value.self is any OpaqueOptional.Type }
}

// MARK: - TransformableProperty

protocol TransformableProperty {
  associatedtype Model: Entity
  var encode: (String, Model, NSManagedObject) throws -> Void { get }
  var decode: (String, inout Model, NSManagedObject) throws -> Void { get }
}

// MARK: - PropertyTrait

public enum PropertyTrait: Sendable {
  case transient
  case allowsCloudEncryption
  case allowsExternalBinaryDataStorage
  case preservesValueInHistoryOnDeletion
}

// MARK: - OptionalWrappedValue

protocol OptionalWrappedValue: OpaqueProperty where Value: OpaqueOptional {}

// MARK: - Attribute + OptionalWrappedValue

extension Attribute: OptionalWrappedValue where Value: OpaqueOptional {}

// MARK: - Relation + OptionalWrappedValue

extension Relation: OptionalWrappedValue where Value: OpaqueOptional {}
