//
//  NSManagedObjectModel+.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import CoreData
import Foundation

extension NSManagedObjectModel {
  convenience init<SomeSchema: Schema>(_: SomeSchema.Type = SomeSchema.self) {
    self.init()

    let entitiesMap = Dictionary(uniqueKeysWithValues: SomeSchema.entities.map { ($0.entityName, EntityDescription($0)) })

    self.entities = entitiesMap.map(\.value)

    for entity in entitiesMap.values {
      for property in entity.properties {
        if let property = property as? NSRelationshipDescription {
          if let relationPropertyInfo = entity.opaquePropertyDescriptors[property.name] as? any OpaqueRelation {
            property.destinationEntity = entitiesMap[relationPropertyInfo.destinationEntity.entityName]
          }
        }
      }
    }
  }
}
