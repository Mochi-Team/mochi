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
    var objectID: ManagedObjectID? { get set }
    static var properties: Set<Property<Self>> { get }

    init()
}

public extension Entity {
    static var entityName: String { .init(describing: Self.self) }
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

        self.objectID = .init(objectID: unmanagedId)

        let managed = context.object(with: unmanagedId)

        for property in Self.properties {
            try property.decode(&self, managed)
        }
    }

    /// Copies Entity instance to managed object
    ///
    func copy(to managedObjectId: NSManagedObjectID, context: NSManagedObjectContext) throws {
        let managed = context.object(with: managedObjectId)

        try Self.properties.forEach { property in
            try property.encode(self, managed)
        }
    }
}
