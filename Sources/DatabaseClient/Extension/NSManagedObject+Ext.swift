//
//  NSManagedObject.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

extension NSManagedObject {
    subscript(primitiveValue forKey: String) -> Any? {
        get {
            defer { didAccessValue(forKey: forKey) }
            willAccessValue(forKey: forKey)
            return primitiveValue(forKey: forKey)
        }
        set(newValue) {
            defer { didChangeValue(forKey: forKey) }
            willChangeValue(forKey: forKey)
            setPrimitiveValue(newValue, forKey: forKey)
        }
    }
}
