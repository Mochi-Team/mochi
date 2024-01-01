//
//  Attribute.swift
//
//
//  Created by ErrorErrorError on 5/17/23.
//
//

import CoreData
import Foundation

// MARK: - Attribute

public struct Attribute<Model: Entity, Value: TransformableValue>: OpaqueAttribute, TransformableProperty {
  public let name: String?
  public let traits: Set<PropertyTrait>
  public let keyPath: WritableKeyPath<Model, Value>

  // TODO: Add default value?

  let decode: (String, inout Model, NSManagedObject) throws -> Void
  let encode: (String, Model, NSManagedObject) throws -> Void
}

extension Attribute {
  public init(
    name: String? = nil,
    traits: Set<PropertyTrait> = [],
    _ keyPath: WritableKeyPath<Model, Value>
  ) {
    self.name = name
    self.traits = traits
    self.keyPath = keyPath
    self.encode = { $2[primitiveValue: name ?? $0] = try $1[keyPath: keyPath].encode() }
    self.decode = { $1[keyPath: keyPath] = try Value.decode(value: $2[primitiveValue: name ?? $0]) }
  }
}

// MARK: Sendable

extension Attribute: @unchecked Sendable where Value: Sendable {}

// MARK: - OpaqueAttribute

protocol OpaqueAttribute: OpaqueProperty where Self.Value: TransformableValue {}
