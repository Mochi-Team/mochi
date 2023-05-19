//
//  Entity.swift
//  
//
//  Created by ErrorErrorError on 5/15/23.
//  
//

import CoreData
import Foundation

public protocol Entity: OpaqueEntity {}

public protocol OpaqueEntity {
    init()

    static var entityName: String { get }
}

extension OpaqueEntity {
    public static var entityName: String {
        String(describing: Self.self)
    }

//    static var relationEntitiesNames: [String] {
//        Self.allStructEntityPropertiesKeyPath.values.compactMap { $0.value as? OpaqueRelation.Type }.map { $0.DestinationEntity.entityName }
//    }
}

extension KeyPath {
    static var value: Value.Type {
        Value.self
    }
}

extension OpaqueEntity {
    var properties: [any OpaqueProperty] {
        var properties = [any OpaqueProperty]()

        for (name, keyPath) in Self.allStructEntityPropertiesKeyPath {
            let property = self[keyPath: keyPath]
            if !property.hasInitialized {
                property.name.value = .init(name.dropFirst())
            }
            properties.append(property)
        }
        return properties
    }

    var mainManagedObjectId: NSManagedObjectID? {
        get {
            for property in properties {
                if let _managedObjectId = property.managedObjectId.value {
                    return _managedObjectId
                }
            }
            return nil
        }
        set { properties.forEach { $0.managedObjectId.value = newValue } }
    }
}

public enum EntityError: Error {
    case managedObjectIdIsNotPermanent
}

extension OpaqueEntity {

    /// Decodes an NSManagedObject data to Entity type
    ///
    init(id: NSManagedObjectID, context: NSManagedObjectContext) throws {
        guard !id.isTemporaryID else {
            throw EntityError.managedObjectIdIsNotPermanent
        }

        try self.init(unmanagedId: id, context: context)
    }

    init(unmanagedId: NSManagedObjectID, context: NSManagedObjectContext) throws {
        self.init()

        for property in properties {
            property.managedObjectId.value = unmanagedId
            try property.decode(from: unmanagedId, context: context)
        }
    }

    /// Copies Entity instance to managed object
    ///
    func copy(
        to managedObjectId: NSManagedObjectID,
        context: NSManagedObjectContext,
        createNewRelations: Bool = true
    ) throws {
        try properties.forEach { property in
            try property.encode(with: managedObjectId, context: context)
        }
    }
}

/// KeyPath
///
var _membersToKeyPaths: [String: [String: AnyKeyPath]] = [:]

extension OpaqueEntity {
    private subscript(checkedMirrorDescendant key: String) -> any OpaqueProperty {
        (Mirror(reflecting: self).descendant(key) as? any OpaqueProperty).unsafelyUnwrapped
    }

    static var allStructEntityPropertiesKeyPath: [String: KeyPath<Self, any OpaqueProperty>] {
        if let entityKeyPathMaps = _membersToKeyPaths[Self.entityName] as? [String: KeyPath<Self, any OpaqueProperty>] {
            return entityKeyPathMaps
        } else {
            var keyPaths = [String: KeyPath<Self, any OpaqueProperty>]()
            defer { _membersToKeyPaths[Self.entityName] = keyPaths as [String: KeyPath<Self, any OpaqueProperty>] }

            let mirror = Mirror(reflecting: Self())

            for case let (key?, value) in mirror.children {
                if !(value is any OpaqueProperty) {
                    continue
                }

                keyPaths[key] = \Self.[checkedMirrorDescendant: key]
            }
            return keyPaths
        }
    }
}
