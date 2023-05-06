//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/3/23.
//  
//

import CoreData
import Foundation

public protocol MORepresentable: Sendable {
    associatedtype EntityID: ConvertableValue & Equatable
    static var idKeyPath: KeyPath<Self, EntityID> { get }
    static var entityName: String { get }
    static var attributes: Set<Attribute<Self>> { get }

    static func createEmptyValue() -> Self
}

extension MORepresentable {
    static func attribute(_ keyPath: KeyPath<Self, some Any>) -> Attribute<Self> {
        attributes.first { $0.keyPath == keyPath }.unsafelyUnwrapped
    }

    @discardableResult
    func encodeAttributes(to managedObject: NSManagedObject) throws -> NSManagedObject {
        try Self.attributes.forEach { attribute in
            try attribute.encode(self, managedObject)
        }
        return managedObject
    }

    init(from managed: NSManagedObject) throws {
        self = Self.createEmptyValue()
        try Self.attributes.forEach { attribute in
            try attribute.decode(&self, managed)
        }
    }
}
