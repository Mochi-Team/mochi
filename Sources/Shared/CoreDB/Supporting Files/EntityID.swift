//
//  EntityID.swift
//
//
//  Created by ErrorErrorError on 9/18/23.
//
//

import CoreData
import Foundation

// MARK: - EntityID

public struct EntityID<T: Entity> {
  var objectID: NSManagedObjectID?
  var hasSet: Bool { objectID != nil }

  public init() {
    self.objectID = nil
  }

  init(objectID: NSManagedObjectID) {
    self.objectID = objectID
  }

  mutating func setObjectID(_ id: NSManagedObjectID?) {
    objectID = id
  }
}

// MARK: Equatable

extension EntityID: Equatable where T: Equatable {}

// MARK: Hashable

extension EntityID: Hashable where T: Hashable {}

// MARK: Sendable

extension EntityID: Sendable where T: Sendable {}
