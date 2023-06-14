//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/11/23.
//
//

import Foundation

public extension Array where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? {
        get { first(where: \.id == id) }
        set {
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

public extension Set where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? {
        get { first(where: \.id == id) }
        set {
            if let index = firstIndex(where: \.id == id) {
                remove(at: index)
                if let newValue {
                    insert(newValue)
                }
            }
        }
    }
}
