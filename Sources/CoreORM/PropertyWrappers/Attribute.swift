//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/17/23.
//  
//

import CoreData
import Foundation

protocol OpaqueAttribute: OpaqueProperty {
    associatedtype Value: TransformableValue
}

extension OpaqueAttribute {
    var transformableType: any TransformableValue.Type {
        Value.self
    }
}

@propertyWrapper
public struct Attribute<Value: TransformableValue, WrappedValue>: OpaqueAttribute {
    public var wrappedValue: WrappedValue {
        get { internalValue.value }
        set { internalValue.value = newValue }
    }
    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    let name: Box<String?> = .init(value: nil)
    var traits: [PropertyTrait] = []

    let managedObjectId = Box<NSManagedObjectID?>(value: nil)

    let internalValue: Box<WrappedValue>

    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue = nil,
        name: String? = nil,
        traits: [PropertyTrait] = []
    ) where WrappedValue == Value? {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name.value = name
        self.traits = traits
    }

    public init(
        wrappedValue: @autoclosure @escaping () -> WrappedValue,
        name: String? = nil,
        traits: [PropertyTrait] = []
    ) where WrappedValue == Value {
//        self.wrappedValue = wrappedValue()
        self.internalValue = .init(value: wrappedValue())
        self.name.value = name
        self.traits = traits
    }

    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue = nil,
        name: String? = nil,
        traits: [PropertyTrait] = []
    ) where WrappedValue == Value? {
//        self.wrappedValue = wrappedValue
        self.internalValue = .init(value: wrappedValue)
        self.name.value = name
        self.traits = traits
    }

    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        name: String? = nil,
        traits: [PropertyTrait] = []
    ) where Value == WrappedValue {
//        self.wrappedValue = wrappedValue
        self.internalValue = .init(value: wrappedValue)
        self.name.value = name
        self.traits = traits
    }
}

extension Attribute {
    static subscript<EscapingSelf: Entity>(
        _ instance: EscapingSelf,
        wrapper wrapperKeyPath: ReferenceWritableKeyPath<EscapingSelf, WrappedValue>,
        storage storageKeyPath: ReferenceWritableKeyPath<EscapingSelf, Attribute<Value, WrappedValue>>
    ) -> WrappedValue {
        get { instance[keyPath: storageKeyPath].wrappedValue }
        set { instance[keyPath: storageKeyPath].wrappedValue = newValue }
    }
}

extension Attribute: @unchecked Sendable where WrappedValue: Sendable {}

extension Attribute: Equatable where WrappedValue: Equatable {
    public static func == (lhs: Attribute<Value, WrappedValue>, rhs: Attribute<Value, WrappedValue>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Attribute: Hashable where WrappedValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}
