//
//  EntityDescription.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import CoreData
import Foundation

@objc(EntityDescription)
class EntityDescription: NSEntityDescription {
  var opaquePropertyDescriptors: [String: any OpaqueProperty] = [:]

  convenience init(_ type: (some Entity).Type) {
    self.init()
    self.name = type.entityName
    self.properties = type._$properties.compactMap { property in
      if let descriptor = try? property.asPropertyDescriptor() {
        opaquePropertyDescriptors[descriptor.name] = property.property
        return descriptor
      } else {
        #if DEBUG
        print(
          """
          Member '\(property.propertyName)' for Entity '\(type.entityName)' is not a valid property
          descriptor for Core Data. Will skip this property.
          """
        )
        #endif
        return nil
      }
    }
  }

  override init() {
    super.init()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
