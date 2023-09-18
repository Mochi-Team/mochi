//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import CoreData
import Dependencies
import Foundation
import XCTestDynamicOverlay

public extension DatabaseClient {
    static var liveValue: DatabaseClient = {
        let persistence = NSPersistentContainer(name: "MochiSchema")

        return .init {
            try await persistence.loadPersistentStores()
        } insert: { instance in
            let managed = try await persistence.schedule { context in
                let managed = context.insert(entity: type(of: instance).self)
                try instance.copy(to: managed.objectID, context: context)
                return managed
            }

            guard !managed.objectID.isTemporaryID else {
                throw Error.managedObjectIdIsTemporary
            }

            let managedId = managed.objectID

//            instance.mainManagedObjectId = managedId
            return instance
        } update: { instance in
            try await persistence.schedule { context in
                guard let objectID = instance.objectID else {
                    throw Error.managedContextNotAvailable
                }
                try instance.copy(to: objectID, context: context)
                return instance
            }
        } delete: { instance in
            try await persistence.schedule { context in
                guard let objectId = instance.objectID else {
                    throw Error.managedContextNotAvailable
                }

                let managed = context.object(with: objectId)
                context.delete(managed)
//                instance.objectID = nil
            }
        } fetch: { entityType, request in
            try await persistence.schedule { context in
                try context.fetch(entityType, request).compactMap { try entityType.init(id: $0.objectID, context: context) }
            }
        }
    }()
}

// MARK: - DatabaseClientError

enum DatabaseClientError: Error {
    case invalidRequestCastType
}

extension DatabaseClient {
    func fetch<Instance: Entity>(_: Instance.Type, _ request: Any) async throws -> [Instance] {
        try await fetch((request as? Request<Instance>) ?? .all)
    }
}

private extension NSManagedObjectContext {
    func fetch<Instance: Entity>(_: Instance.Type, _ request: Any) throws -> [NSManagedObject] {
        try fetch((request as? Request<Instance>) ?? .all)
    }
}
