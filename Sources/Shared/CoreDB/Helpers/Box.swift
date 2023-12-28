//
//  Box.swift
//
//
//  Created by ErrorErrorError on 5/18/23.
//
//

import Foundation

class Box<Value> {
  var value: Value

  init(value: Value) {
    self.value = value
  }

  subscript<IntoValue>(keyPath: WritableKeyPath<Value, IntoValue>) -> IntoValue {
    get { value[keyPath: keyPath] }
    set { value[keyPath: keyPath] = newValue }
  }
}
