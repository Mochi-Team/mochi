//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

extension NSManagedObjectModel {
    convenience init<SomeSchema: Schema>(_: SomeSchema.Type = SomeSchema.self) {
        self.init()

        var entitiesMap = [String: EntityDescriptor]()

        for entity in SomeSchema.entities {
            entitiesMap[entity.entityName] = EntityDescriptor(entity)
        }

        self.entities = entitiesMap.map(\.value)

        for case let entity as EntityDescriptor in entities {
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
