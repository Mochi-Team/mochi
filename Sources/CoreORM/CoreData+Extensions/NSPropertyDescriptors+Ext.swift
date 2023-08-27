//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

extension NSAttributeDescription {
    convenience init<A: OpaqueAttribute>(_ description: A) {
        self.init()

        name = description.name.value ?? ""
        isOptional = description.isOptionalType
        isTransient = description.traits.contains(.transient)
        allowsExternalBinaryDataStorage = description.traits.contains(.allowsExternalBinaryDataStorage)
        allowsCloudEncryption = description.traits.contains(.allowsCloudEncryption)
        preservesValueInHistoryOnDeletion = description.traits.contains(.preservesValueInHistoryOnDeletion)
        defaultValue = try? description.wrappedValue.encode()
        attributeType = A.WrappedValue.Primitive.attributeType
    }
}

extension NSRelationshipDescription {
    convenience init(_ description: any OpaqueRelation) {
        self.init()

        name = description.name.value ?? ""
        isOptional = description.isOptionalType
        isTransient = description.traits.contains(.transient)
        isOrdered = description.isOrdered
        deleteRule = description.deleteRule

        switch description.relationType {
        case .toOne:
            minCount = isOptional ? 0 : 1
            maxCount = 1
        case .toMany:
            minCount = 0
            maxCount = 0
        }
    }
}
