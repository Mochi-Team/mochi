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
    convenience init(_ description: any OpaqueAttribute) {
        self.init()

        name = description.name.value ?? ""
        isOptional = description.isOptional
        isTransient = description.traits.contains(.transient)
        allowsExternalBinaryDataStorage = description.traits.contains(.allowsExternalBinaryDataStorage)
        allowsCloudEncryption = description.traits.contains(.allowsCloudEncryption)
        preservesValueInHistoryOnDeletion = description.traits.contains(.preservesValueInHistoryOnDeletion)
        defaultValue = description.wrappedValue

        if let valueType = Swift.type(of: description.wrappedValue) as? any TransformableValue.Type {
            attributeType = valueType._attributeType
        } else if let value = description.wrappedValue as? _OptionalType, let bro = value.wrappedType() as? any TransformableValue.Type {
            attributeType = bro._attributeType
        } else {
            assertionFailure("This value type is unsupported")
        }
    }
}

extension NSRelationshipDescription {
    convenience init(_ description: any OpaqueRelation) {
        self.init()

        name = description.name.value ?? ""
        isOptional = description.isOptional
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
