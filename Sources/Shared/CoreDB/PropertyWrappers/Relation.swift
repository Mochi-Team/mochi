//
//  Relation.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

// MARK: - Relation

@propertyWrapper
public struct Relation<DestinationEntity: Entity, WrappedValue>: OpaqueRelation {
  public var wrappedValue: WrappedValue

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  let name: Box<String?>
  let traits: Set<PropertyTrait>
  let deleteRule: NSDeleteRule
  let isOrdered: Bool

  /// This represents an optional to one relationship
  ///
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule
  ) where WrappedValue == DestinationEntity? {
    self.wrappedValue = wrappedValue()
    self.name = .init(value: name)
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
  }

  /// This represents to one relationship
  ///
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue,
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule
  ) where WrappedValue == DestinationEntity {
    self.wrappedValue = wrappedValue()
    self.name = .init(value: name)
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
  }

  /// This represents an optional to-many relationship set
  ///
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule
  ) where WrappedValue == Set<DestinationEntity>? {
    self.wrappedValue = wrappedValue()
    self.name = .init(value: name)
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
  }

  /// This represents to-many relationship set
  ///
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue,
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule
  ) where WrappedValue == Set<DestinationEntity> {
    self.wrappedValue = wrappedValue()
    self.name = .init(value: name)
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
  }

  /// This represents an optional to-many relationship ordered array
  ///
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule
  ) where WrappedValue == [DestinationEntity]? {
    self.wrappedValue = wrappedValue()
    self.name = .init(value: name)
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = true
  }

  /// This represents to-many relationship ordered array
  ///
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue,
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule
  ) where WrappedValue == [DestinationEntity] {
    self.wrappedValue = wrappedValue()
    self.name = .init(value: name)
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = true
  }
}

// MARK: Sendable

extension Relation: @unchecked Sendable where WrappedValue: Sendable {}

// MARK: Equatable

extension Relation: Equatable where WrappedValue: Equatable {
  public static func == (
    lhs: Relation<DestinationEntity, WrappedValue>,
    rhs: Relation<DestinationEntity, WrappedValue>
  ) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}

// MARK: Hashable

extension Relation: Hashable where WrappedValue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(wrappedValue)
  }
}

// MARK: - OpaqueRelation

protocol OpaqueRelation: OpaqueProperty {
  associatedtype DestinationEntity: OpaqueEntity
  var deleteRule: NSDeleteRule { get }
  var isOrdered: Bool { get }
}

// MARK: - RelationType

enum RelationType {
  case toOne
  case toMany
}

extension OpaqueRelation {
  var destinationEntity: DestinationEntity.Type { DestinationEntity.self }

  var relationType: RelationType {
    if WrappedValue.self is DestinationEntity.Type {
      .toOne
    } else if WrappedValue.self is DestinationEntity?.Type {
      .toOne
    } else {
      .toMany
    }
  }
}
