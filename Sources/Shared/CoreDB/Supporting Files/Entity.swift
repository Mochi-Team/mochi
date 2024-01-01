//
//  Entity.swift
//
//
//  Created by ErrorErrorError on 9/12/23.
//
//

import CoreData
import Foundation

// MARK: - Entity

public protocol Entity {
  static var entityName: String { get }

  var _$id: EntityID<Self> { get set }
  static var _$properties: Set<AnyProperty<Self>> { get }

  init()
}

extension Entity {
  public static var entityName: String { .init(describing: Self.self) }
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
    _$id.setObjectID(unmanagedId)

    let managed = context.object(with: unmanagedId)

    for property in Self._$properties {
      try property.decode(&self, managed)
    }
  }

  /// Copies Entity instance to managed object
  ///
  func encode(to managedObjectId: NSManagedObjectID, context: NSManagedObjectContext) throws {
    let managed = context.object(with: managedObjectId)

    try Self._$properties.forEach { property in
      try property.encode(self, managed)
    }
  }
}
