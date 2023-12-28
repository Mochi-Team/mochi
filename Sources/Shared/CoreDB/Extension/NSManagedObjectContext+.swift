//
//  NSManagedObjectContext+.swift
//
//
//  Created by ErrorErrorError on 5/3/23.
//
//

import CoreData
import Foundation

extension NSManagedObjectContext {
  public func insert(entity type: any Entity.Type) -> NSManagedObject {
    NSEntityDescription.insertNewObject(forEntityName: type.entityName, into: self)
  }

  public func fetch(_ request: Request<some Entity>) throws -> [NSManagedObject] {
    try fetch(request.makeFetchRequest())
  }

  public func delete(_ request: Request<some Entity>) throws {
    let items = try fetch(request)

    for item in items {
      delete(item)
    }
  }

  @discardableResult
  public func execute<T>(_ callback: @Sendable @escaping (NSManagedObjectContext) throws -> T) throws -> T {
    defer { self.reset() }

    let value = try callback(self)

    if hasChanges {
      try save()
    }

    return value
  }
}
