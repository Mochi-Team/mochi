//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/17/23.
//
//

import CoreData
import Foundation

// MARK: - AnyAttribute

@propertyWrapper
public struct AnyAttribute<EnclosingEntity: Entity, WrappedValue: TransformableValue>: OpaqueAttribute {
    public var wrappedValue: WrappedValue
    public var projectedValue: Self {
        get { self }
        mutating set { self = newValue }
    }

    var name: String
    var objectID: NSManagedObjectID?
    var keyPath: PartialKeyPath<EnclosingEntity>

    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        _ name: String,
        _ keyPath: WritableKeyPath<EnclosingEntity, WrappedValue>
    ) {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.keyPath = keyPath
    }
}

// MARK: Sendable

extension AnyAttribute: @unchecked Sendable where WrappedValue: Sendable {}

// MARK: Equatable

extension AnyAttribute: Equatable where WrappedValue: Equatable {
    public static func == (lhs: AnyAttribute<EnclosingEntity, WrappedValue>, rhs: AnyAttribute<EnclosingEntity, WrappedValue>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

// MARK: Hashable

extension AnyAttribute: Hashable where WrappedValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

// MARK: - OpaqueAttribute

protocol OpaqueAttribute: OpaqueProperty where WrappedValue: TransformableValue {}
