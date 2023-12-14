//
//  Array+ID.swift
//
//
//  Created by ErrorErrorError on 5/11/23.
//
//

import Foundation

extension Array where Element: Identifiable {
  public subscript(id id: Element.ID) -> Element? {
    get { first(where: \.id == id) }
    mutating set {
      if let index = firstIndex(where: \.id == id) {
        if let newValue {
          self[index] = newValue
        } else {
          remove(at: index)
        }
      }
    }
  }
}

extension Set where Element: Identifiable {
  public subscript(id id: Element.ID) -> Element? {
    get { first(where: \.id == id) }
    mutating set {
      if let index = firstIndex(where: \.id == id) {
        remove(at: index)
        if let newValue {
          insert(newValue)
        }
      }
    }
  }
}
