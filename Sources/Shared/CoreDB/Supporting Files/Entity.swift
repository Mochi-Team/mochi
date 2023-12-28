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

// @dynamicMemberLookup
// public struct Model<T: Entity> {
//   public var model: T
//   var _$id: EntityID?

//   subscript<Member>(dynamicMember keyPath: WritableKeyPath<T, Member>) -> Member {
//     get { model[keyPath: keyPath] }
//     set { model[keyPath: keyPath] = newValue }
//   }
// }

// extension Model: Sendable where T: Sendable {}

public protocol Entity: OpaqueEntity {
  static var entityName: String { get }
  static var properties: Set<Property<Self>> { get }

  var _$id: EntityID { get }

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
  public init(id: NSManagedObjectID, context: NSManagedObjectContext) throws {
    guard !id.isTemporaryID else {
      throw EntityError.managedObjectIdIsNotPermanent
    }

    try self.init(unmanagedId: id, context: context)
  }

  public init(unmanagedId: NSManagedObjectID, context: NSManagedObjectContext) throws {
    self.init()
//    self._$id = .init(objectID: unmanagedId)

    let managed = context.object(with: unmanagedId)

    for property in Self.properties {
      try property.decode(&self, managed)
    }
  }

  /// Copies Entity instance to managed object
  ///
  public func copy(to managedObjectId: NSManagedObjectID, context: NSManagedObjectContext) throws {
    let managed = context.object(with: managedObjectId)

    try Self.properties.forEach { property in
      try property.encode(self, managed)
    }
  }
}

// MARK: - OpaqueEntity

public protocol OpaqueEntity {}
