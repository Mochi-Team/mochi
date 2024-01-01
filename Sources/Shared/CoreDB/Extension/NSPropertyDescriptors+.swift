//
//  NSPropertyDescriptors+.swift
//
//
//  Created by ErrorErrorError on 12/30/23.
//
//

import CoreData
import Foundation

extension NSAttributeDescription {
  convenience init<A: OpaqueAttribute>(_ memberName: String, _ property: A) {
    self.init()

    name = property.name ?? memberName
    isOptional = property.isOptionalType
    isTransient = property.traits.contains(.transient)
    allowsExternalBinaryDataStorage = property.traits.contains(.allowsExternalBinaryDataStorage)
    allowsCloudEncryption = property.traits.contains(.allowsCloudEncryption)
    preservesValueInHistoryOnDeletion = property.traits.contains(.preservesValueInHistoryOnDeletion)
    // defaultValue = try? A.Model()[keyPath: property.keyPath].encode()
    attributeType = A.Value.Primitive.attributeType
  }
}

extension NSRelationshipDescription {
  convenience init(_ memberName: String, _ property: some OpaqueRelation) {
    self.init()

    name = property.name ?? memberName
    isOptional = property.isOptionalType
    isTransient = property.traits.contains(.transient)
    isOrdered = property.isOrdered
    deleteRule = property.deleteRule

    switch property.relationType {
    case .toOne:
      minCount = isOptional ? 0 : 1
      maxCount = 1
    case .toMany:
      minCount = 0
      maxCount = 0
    }
  }
}
