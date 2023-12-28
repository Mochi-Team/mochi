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

@propertyWrapper
public struct Attribute<WrappedValue: TransformableValue>: OpaqueAttribute {
  public var wrappedValue: WrappedValue
  public var projectedValue: Self { self }

  let name: Box<String?> = .init(value: nil)
  let traits: Set<PropertyTrait>

  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue,
    name: String? = nil,
    traits: Set<PropertyTrait> = []
  ) {
    self.wrappedValue = wrappedValue()
    self.name.value = name
    self.traits = traits
  }
}

extension Attribute where WrappedValue.Primitive == Data {
  public init(
    wrappedValue: @autoclosure @escaping () -> WrappedValue,
    name: String? = nil,
    traits: Set<PropertyTrait> = [],
    allowsExternalBinaryDataStorage: Bool = false
  ) {
    self.wrappedValue = wrappedValue()
    self.name.value = name
    self.traits = traits.union(allowsExternalBinaryDataStorage ? [.allowsExternalBinaryDataStorage] : [])
  }
}

extension Attribute {
  static subscript<EscapingSelf: Entity>(
    _ instance: EscapingSelf,
    wrapper _: ReferenceWritableKeyPath<EscapingSelf, WrappedValue>,
    storage storageKeyPath: ReferenceWritableKeyPath<EscapingSelf, Attribute<WrappedValue>>
  ) -> WrappedValue {
    get { instance[keyPath: storageKeyPath].wrappedValue }
    set { instance[keyPath: storageKeyPath].wrappedValue = newValue }
  }
}

// MARK: Sendable

extension Attribute: @unchecked Sendable where WrappedValue: Sendable {}

// MARK: Equatable

extension Attribute: Equatable where WrappedValue: Equatable {
  public static func == (lhs: Attribute<WrappedValue>, rhs: Attribute<WrappedValue>) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}

// MARK: Hashable

extension Attribute: Hashable where WrappedValue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(wrappedValue)
  }
}

// MARK: - OpaqueAttribute

protocol OpaqueAttribute: OpaqueProperty where WrappedValue: TransformableValue {}
