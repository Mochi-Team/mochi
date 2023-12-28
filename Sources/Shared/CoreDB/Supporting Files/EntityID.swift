//
//  EntityID.swift
//
//
//  Created by ErrorErrorError on 9/18/23.
//
//

import CoreData
import Foundation

public struct EntityID: Hashable, @unchecked Sendable {
  public private(set) var objectID: NSManagedObjectID?

  var hasSet: Bool { objectID != nil }

  public init() {
    self.objectID = nil
  }

  init(objectID: NSManagedObjectID) {
    self.objectID = objectID
  }

  public func _$objectID(_ newId: NSManagedObjectID?) -> Self {
    var copy = self
    copy.objectID = newId
    return copy
  }
}
