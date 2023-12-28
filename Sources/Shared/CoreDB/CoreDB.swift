//
//  CoreDB.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

@preconcurrency
import CoreData
import Foundation

// MARK: - CoreORM

public final class CoreORM<SomeSchema: Schema>: @unchecked Sendable {
  private var pc: NSPersistentContainer

  public init() {
    let managedObjectModel = NSManagedObjectModel(SomeSchema.self)

    self.pc = .init(
      name: SomeSchema.schemaName,
      managedObjectModel: managedObjectModel
    )

    setupPersistentStores()
  }

  @MainActor
  public func load() async throws {
    try await performMigrationCheck()
    try await loadPersistentStoreIfNeeded()
  }

  @discardableResult
  public func transaction<R: Sendable>(_ body: @Sendable @escaping (CoreTransaction<SomeSchema>) async throws -> R) async rethrows -> R {
    try await body(.init(persistenceContainer: pc))
  }

  public func observe<Instance: Entity>(_ request: Request<Instance>) -> AsyncStream<[Instance]> {
    CoreTransaction<SomeSchema>(persistenceContainer: pc).observe(request: request)
  }

  @MainActor
  public func reset() async throws {
    if pc.viewContext.hasChanges {
      pc.viewContext.rollback()
      pc.viewContext.reset()
    }

    for store in pc.persistentStoreCoordinator.persistentStores {
      try store.destroy(pc.persistentStoreCoordinator)
    }

    try allStoreFiles.forEach { url in
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
    }

    pc = .init(
      name: pc.name,
      managedObjectModel: pc.managedObjectModel
    )
  }
}

extension CoreORM {
  @MainActor
  private func performMigrationCheck() async throws {
    // TODO: Perform Migration
  }

  private func loadPersistentStoreIfNeeded() async throws {
    setupPersistentStores()

    guard pc.persistentStoreCoordinator.persistentStores.isEmpty else {
      return
    }

    try await pc.loadPersistentStores()
  }

  private func setupPersistentStores() {
    guard pc.persistentStoreDescriptions.isEmpty else {
      return
    }

    if let sqliteStoreURL = pc.persistentStoreDescriptions.first?.url {
      let storeDescription = NSPersistentStoreDescription(url: sqliteStoreURL)

      storeDescription.shouldInferMappingModelAutomatically = true
      storeDescription.shouldMigrateStoreAutomatically = true
      storeDescription.type = NSSQLiteStoreType

      pc.persistentStoreDescriptions = [storeDescription]
    }
  }
}

// MARK: - CoreTransaction

public struct CoreTransaction<SomeSchema: Schema>: Sendable {
  let persistenceContainer: NSPersistentContainer

  public func create<Instance: Entity>(_: Instance.Type = Instance.self) async throws -> Instance {
    try await create(Instance())
  }

  @discardableResult
  public func create<Instance: Entity>(_ instance: Instance) async throws -> Instance {
    let managed = try await persistenceContainer.schedule { context in
      let managed = context.insert(entity: Instance.self)
      try instance.copy(to: managed.objectID, context: context)
      return managed
    }

    guard !managed.objectID.isTemporaryID else {
      throw Error.managedObjectIdIsTemporary
    }

    let managedId = managed.objectID

    return try await persistenceContainer.schedule { context in
      try .init(id: managedId, context: context)
    }
  }

  @discardableResult
  public func createOrUpdate<Instance: Entity>(_ instance: Instance) async throws -> Instance {
    if instance._$id.objectID != nil {
      try await update(instance)
    } else {
      try await create(instance)
    }
  }

  @discardableResult
  public func update<Instance: Entity>(_ instance: Instance) async throws -> Instance {
    try await persistenceContainer.schedule { context in
      guard let objectId = instance._$id.objectID else {
        throw Error.managedContextNotAvailable
      }

      try instance.copy(to: objectId, context: context)
      return instance
    }
  }

  public func delete(_ instance: some Entity) async throws {
    try await persistenceContainer.schedule { context in
      guard let objectId = instance._$id.objectID else {
        throw Error.managedContextNotAvailable
      }

      let managed = context.object(with: objectId)
      context.delete(managed)
      // instance.properties.forEach { $0.managedObjectId.value = nil }
    }
  }

  public func fetch<Instance: Entity>(_ request: Request<Instance> = .all) async throws -> [Instance] {
    try await persistenceContainer.schedule { context in
      try context.fetch(request).compactMap { try .init(id: $0.objectID, context: context) }
    }
  }

  public func observe<Instance: Entity>(request: Request<Instance>) -> AsyncStream<[Instance]> {
    .init { continuation in
      let cancellable = Task.detached {
        let values = try? await fetch(request)
        continuation.yield(values ?? [])

        let notifications = NotificationCenter.default.notifications(
          named: Notification.Name.NSManagedObjectContextDidSave
        )

        for await notification in notifications {
          // TODO: Include entity relations

          let hasChanges = notification.userInfo?.contains { _, value in
            if let objects = value as? Set<NSManagedObject> {
              return objects.contains { $0.entity.name == Instance.entityName }
            }
            return false
          } ?? false

          if hasChanges {
            let values = try? await fetch(request)
            continuation.yield(values ?? [])
          }
        }
      }
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }
}

// MARK: CoreTransaction.Error

extension CoreTransaction {
  public enum Error: Swift.Error {
    case failedToCreateInstance
    case managedContextNotAvailable
    case managedObjectIdIsTemporary
  }
}

extension CoreORM {
  var sqliteStoreURL: URL? {
    pc.persistentStoreDescriptions.first?.url
  }

  var allStoreFiles: [URL] {
    if let fileURL = sqliteStoreURL {
      var result: [URL] = []
      let externalStorageFolderName = ".\(fileURL.deletingPathExtension().lastPathComponent)_SUPPORT"

      result.append(fileURL.deletingLastPathComponent().appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist"))
      result.append(fileURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
      result.append(fileURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
      result.append(fileURL.deletingLastPathComponent().appendingPathComponent(externalStorageFolderName, isDirectory: true))
      result.append(fileURL)
      return result
    }
    return []
  }
}
