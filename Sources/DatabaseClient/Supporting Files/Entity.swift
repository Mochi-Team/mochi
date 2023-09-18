//
//  File.swift
//  
//
//  Created by ErrorErrorError on 9/12/23.
//  
//

import CoreData
import Foundation

public protocol Entity {
    static var entityName: String { get }
    static var properties: Set<AnyProperty<Self>> { get }

    var objectID: NSManagedObjectID? { get set }

    init()
}

public extension Entity {
    static var entityName: String { .init(describing: Self.self) }
}

extension Entity {

//    var mainManagedObjectId: NSManagedObjectID? {
//        get {
//            for (_, keyPath) in Self.allStructEntityPropertiesKeyPath {
//                let property = self[keyPath: keyPath]
//                if let _managedObjectId = property.objectID {
//                    return _managedObjectId
//                }
//            }
//            return nil
//        }
//        mutating set {
//            properties.forEach { $0.objectID = newValue }
//        }
//    }

//    var properties: [any OpaqueProperty] {
//        var properties = [any OpaqueProperty]()
//
//        for (_, keyPath) in Self.allStructEntityPropertiesKeyPath {
//            let property = self[keyPath: keyPath]
//            properties.append(property)
//        }
//        return properties
//    }

    static var properties: Set<PartialKeyPath<Self>> { [] }
}

// MARK: - EntityError

public enum EntityError: Error {
    case managedObjectIdIsNotPermanent
}

extension Entity {
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
    }

    /// Copies Entity instance to managed object
    ///
    func copy(
        to managedObjectId: NSManagedObjectID,
        context: NSManagedObjectContext,
        createNewRelations _: Bool = true
    ) throws {
//        try properties.forEach { property in
//            try property.encode(with: managedObjectId, context: context)
//        }
    }
}

///// KeyPath
/////
//var _membersToKeyPaths: [String: [String: AnyKeyPath]] = [:]
//
//extension Entity {
//    private subscript(checkedMirrorDescendant key: String) -> any OpaqueProperty {
//        (Mirror(reflecting: self).descendant(key) as? any OpaqueProperty).unsafelyUnwrapped
//    }
//
//    static var allStructEntityPropertiesKeyPath: [String: KeyPath<Self, any OpaqueProperty>] {
//        if let entityKeyPathMaps = _membersToKeyPaths[Self.entityName] as? [String: KeyPath<Self, any OpaqueProperty>] {
//            return entityKeyPathMaps
//        } else {
//            var keyPaths = [String: KeyPath<Self, any OpaqueProperty>]()
//            defer { _membersToKeyPaths[Self.entityName] = keyPaths as [String: KeyPath<Self, any OpaqueProperty>] }
//
//            let mirror = Mirror(reflecting: Self())
//
//            for case let (key?, value) in mirror.children {
//                if !(value is any OpaqueProperty) {
//                    continue
//                }
//
//                keyPaths[key] = \Self.[checkedMirrorDescendant: key]
//            }
//            return keyPaths
//        }
//    }
//}

public extension Entity {
    typealias Property = AnyProperty<Self>
    typealias Attribute<T: TransformableValue> = AnyAttribute<Self, T>
    typealias Relation<D: Entity, T> = AnyRelation<Self, D, T>
}
