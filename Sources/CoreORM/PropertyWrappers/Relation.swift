//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/15/23.
//  
//

import CoreData
import Foundation

// swiftlint:disable type_name
protocol OpaqueRelation: OpaqueProperty {
    associatedtype DestinationEntity: OpaqueEntity
    var deleteRule: NSDeleteRule { get }
    var isOrdered: Bool { get }
}

extension OpaqueRelation {
    var _opaque_destinationEntity: DestinationEntity.Type { DestinationEntity.self }

    var relationType: _RelationType {
        if WrappedValue.self is DestinationEntity.Type {
            return .toOne
        } else if WrappedValue.self is DestinationEntity?.Type {
            return .toOne
        } else {
            return .toMany
        }
    }
}

enum _RelationType {
    case toOne
    case toMany
}

@propertyWrapper
public struct Relation<DestinationEntity: Entity, WrappedValue>: OpaqueRelation {
    public var wrappedValue: WrappedValue {
        get { internalValue.value }
        set { internalValue.value = newValue }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    var name: Box<String?>
    var traits: [PropertyTrait] = []
    var deleteRule = NSDeleteRule.cascadeDeleteRule
    var isOrdered = false

    var managedObjectId = Box<NSManagedObjectID?>(value: nil)

    var internalValue: Box<WrappedValue>

    /// This represents an optional to one relationship
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        name: String? = nil,
        isTransient: Bool = false,
        deleteRule: NSDeleteRule = .cascadeDeleteRule
    ) where WrappedValue == DestinationEntity? {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name = .init(value: name)
        self.traits = isTransient ? [.transient] : []
        self.deleteRule = deleteRule
    }

    /// This represents to one relationship
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        name: String? = nil,
        isTransient: Bool = false,
        deleteRule: NSDeleteRule = .cascadeDeleteRule
    ) where WrappedValue == DestinationEntity {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name = .init(value: name)
        self.traits = isTransient ? [.transient] : []
        self.deleteRule = deleteRule
    }

    /// This represents an optional to-many relationship set
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        name: String? = nil,
        isTransient: Bool = false,
        deleteRule: NSDeleteRule = .cascadeDeleteRule
    ) where WrappedValue == Set<DestinationEntity>? {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name = .init(value: name)
        self.traits = isTransient ? [.transient] : []
        self.deleteRule = deleteRule
    }

    /// This represents to-many relationship set
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        name: String? = nil,
        isTransient: Bool = false,
        deleteRule: NSDeleteRule = .cascadeDeleteRule
    ) where WrappedValue == Set<DestinationEntity> {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name = .init(value: name)
        self.traits = isTransient ? [.transient] : []
        self.deleteRule = deleteRule
    }

    /// This represents an optional to-many relationship ordered array
    ///
    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        name: String? = nil,
        isTransient: Bool = false,
        deleteRule: NSDeleteRule = .cascadeDeleteRule
    ) where WrappedValue == [DestinationEntity]? {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
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
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name = .init(value: name)
        self.traits = isTransient ? [.transient] : []
        self.deleteRule = deleteRule
        self.isOrdered = true
    }
}

extension Relation: @unchecked Sendable where WrappedValue: Sendable {}

extension Relation: Equatable where WrappedValue: Equatable {
    public static func == (lhs: Relation<DestinationEntity, WrappedValue>, rhs: Relation<DestinationEntity, WrappedValue>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Relation: Hashable where WrappedValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}
