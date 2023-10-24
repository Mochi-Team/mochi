//
//  NSManagedObjectContext+Ext.swift
//
//
//  Created by ErrorErrorError on 5/3/23.
//
//

import CoreData
import Foundation

extension NSManagedObjectContext {
    func insert(entity type: any Entity.Type) -> NSManagedObject {
        NSEntityDescription.insertNewObject(forEntityName: type.entityName, into: self)
    }

    func fetch(_ request: Request<some Entity>) throws -> [NSManagedObject] {
        try fetch(request.makeFetchRequest())
    }

    func delete(_ request: Request<some Entity>) throws {
        let items = try fetch(request)

        for item in items {
            delete(item)
        }
    }

    @discardableResult
    func execute<T>(_ callback: @Sendable @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        defer { self.reset() }

        let value = try callback(self)

        if hasChanges {
            try save()
        }

        return value
    }
}
