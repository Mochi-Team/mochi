//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

final class EntityDescriptor: NSEntityDescription {
    var opaquePropertyDescriptors: [String: any OpaqueProperty]

    init(_ type: any OpaqueEntity.Type) {
        let instance = type.init()
        let properties = instance.properties

        self.opaquePropertyDescriptors = [:]

        super.init()

        self.name = type.entityName

        for property in properties {
            if let descriptor = try? property.asPropertyDescriptor() {
                opaquePropertyDescriptors[descriptor.name] = property
                self.properties.append(descriptor)
            } else {
                continue
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
