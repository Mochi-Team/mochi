//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

// MARK: - AnyRelation

@propertyWrapper
public struct AnyRelation<EnclosingEntity: Entity, DestinationEntity: Entity, WrappedValue>: OpaqueRelation {
    public typealias ValueKeyPath = WritableKeyPath<EnclosingEntity, WrappedValue>

    public var wrappedValue: WrappedValue

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    var name: String
    let isOrdered: Bool
    var objectID: NSManagedObjectID?
    var keyPath: PartialKeyPath<EnclosingEntity>

    /// This represents an optional to one relationship
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
        _ name: String,
        _ keyPath: ValueKeyPath
    ) where WrappedValue == DestinationEntity? {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.isOrdered = false
        self.keyPath = keyPath
    }

    /// This represents to one relationship
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        _ name: String,
        _ keyPath: ValueKeyPath
    ) where WrappedValue == DestinationEntity {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.isOrdered = false
        self.keyPath = keyPath
    }

    /// This represents an optional to-many relationship set
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
        _ name: String,
        _ keyPath: ValueKeyPath
    ) where WrappedValue == Set<DestinationEntity>? {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.isOrdered = false
        self.keyPath = keyPath
    }

    /// This represents to-many relationship set
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        _ name: String,
        _ keyPath: ValueKeyPath
    ) where WrappedValue == Set<DestinationEntity> {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.isOrdered = false
        self.keyPath = keyPath
    }

    /// This represents an optional to-many relationship ordered array
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
        _ name: String,
        _ keyPath: ValueKeyPath
    ) where WrappedValue == [DestinationEntity]? {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.isOrdered = true
        self.keyPath = keyPath
    }

    /// This represents to-many relationship ordered array
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        _ name: String,
        _ keyPath: ValueKeyPath
    ) where WrappedValue == [DestinationEntity] {
        self.wrappedValue = wrappedValue()
        self.name = name
        self.isOrdered = true
        self.keyPath = keyPath
    }
}

// MARK: Sendable

extension AnyRelation: @unchecked Sendable where WrappedValue: Sendable {}

// MARK: Equatable

extension AnyRelation: Equatable where WrappedValue: Equatable {
    public static func == (
        lhs: AnyRelation<EnclosingEntity, DestinationEntity, WrappedValue>,
        rhs: AnyRelation<EnclosingEntity, DestinationEntity, WrappedValue>
    ) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

// MARK: Hashable

extension AnyRelation: Hashable where WrappedValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

// MARK: - OpaqueRelation

protocol OpaqueRelation: OpaqueProperty {
    associatedtype DestinationEntity: Entity
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
            return .toOne
        } else if WrappedValue.self is DestinationEntity?.Type {
            return .toOne
        } else {
            return .toMany
        }
    }
}
