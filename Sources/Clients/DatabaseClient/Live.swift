//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import CoreData
import CoreDB
import Dependencies
import Foundation
import XCTestDynamicOverlay

extension DatabaseClient {
  public static var liveValue: DatabaseClient = //    guard let databaseURL = Bundle.module.url(
//      forResource: "MochiSchema",
//      withExtension: "momd"
//    ) else {
//      fatalError("Failed to find data model")
//    }
//
//    let database = databaseURL.deletingPathExtension().lastPathComponent
//
//    guard let managedObjectModel = NSManagedObjectModel(contentsOf: databaseURL) else {
//      fatalError("Failed to create model from file: \(databaseURL)")
//    }
//
//    let persistence = NSPersistentContainer(name: database, managedObjectModel: managedObjectModel)

    .init {
//      try await persistence.loadPersistentStores()
    } insert: { _ in
//      let managed = try await persistence.schedule { context in
//        let managed = context.insert(entity: type(of: instance).self)
//        try instance.copy(to: managed.objectID, context: context)
//        return managed
//      }
//
//      guard !managed.objectID.isTemporaryID else {
      throw Error.managedObjectIdIsTemporary
//      }
//
//      var instance = instance
//      instance._$id._$objectID(managed.objectID)
//      return instance
    } update: { _ in
//      try await persistence.schedule { context in
//        guard let objectId = instance._$id.objectID else {
      throw Error.managedContextNotAvailable
//        }
//        try instance.copy(to: objectId, context: context)
//        return instance
//      }
    } delete: { _ in
//      try await persistence.schedule { context in
//        guard let objectId = instance._$id.objectID else {
//          throw Error.managedContextNotAvailable
//        }
//
//        let managed = context.object(with: objectId)
//        context.delete(managed)
//      }
    } fetch: { _, _ in
//      try await persistence.schedule { context in
//        try context.fetch(entityType, request).compactMap { try entityType.init(id: $0.objectID, context: context) }
//      }
      []
    } observe: { _, _ in
      .never
//      .init { continuation in
//        Task.detached {
//          let fetchValues = {
//            try? await persistence.schedule { ctx in
//              try ctx.fetch(entityType, request).compactMap { try entityType.init(id: $0.objectID, context: ctx) }
//            }
//          }
//
//          await continuation.yield(fetchValues() ?? [])
//
//          let observe = NotificationCenter.default.notifications(named: NSManagedObjectContext.didSaveObjectsNotification)
//
//          for await _ in observe {
//            await continuation.yield(fetchValues() ?? [])
//          }
//        }
//      }
    }
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

extension NSManagedObjectContext {
  fileprivate func fetch<Instance: Entity>(_: Instance.Type, _ request: Any) throws -> [NSManagedObject] {
    try fetch((request as? Request<Instance>) ?? .all)
  }
}
