//
//  EntityDescriptor.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import CoreData
import Foundation

final class EntityDescriptor: NSEntityDescription {
  var opaquePropertyDescriptors: [String: any OpaqueProperty]

  init(_ type: any Entity.Type) {
    let instance = type.init()
    // let properties = instance.properties

    self.opaquePropertyDescriptors = [:]

    super.init()

    self.name = type.entityName

//    for property in properties {
//      if let descriptor = try? property.asPropertyDescriptor() {
//        opaquePropertyDescriptors[descriptor.name] = property
//        self.properties.append(descriptor)
//      } else {
//        print(
//          """
//          Property '\(property.name.value ?? "Unknown")' for Entity '\(type.entityName)' is not a valid property
//          descriptor for Core Data. Will skip this property.
//          """
//        )
//        continue
//      }
//    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
