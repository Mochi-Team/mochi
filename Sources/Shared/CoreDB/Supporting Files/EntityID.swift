//
//  EntityID.swift
//
//
//  Created by ErrorErrorError on 9/18/23.
//
//

import CoreData
import Foundation

public struct EntityID<T: Entity>: Hashable, @unchecked Sendable {
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
