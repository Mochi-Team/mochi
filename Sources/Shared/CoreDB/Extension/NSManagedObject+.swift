//
//  NSManagedObject+.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

extension NSManagedObject {
  subscript<V: PrimitiveValue>(primitiveValue key: String) -> V {
    get {
      willAccessValue(forKey: key)
      defer { didAccessValue(forKey: key) }

      let value = primitiveValue(forKey: key)
      if let value = value as? V {
        return value
      } else {
        if V.self is OpaqueOptional.Type {
          return unsafeBitCast(value, to: V.self)
        } else {
          return unsafeBitCast(value, to: V.self)
        }
      }
    }

    set(newValue) {
      willChangeValue(forKey: key)
      defer { didChangeValue(forKey: key) }
      if let optional = newValue as? OpaqueOptional {
        setPrimitiveValue(optional.isNil ? nil : newValue, forKey: key)
      } else {
        setPrimitiveValue(newValue, forKey: key)
      }
    }
  }
}
