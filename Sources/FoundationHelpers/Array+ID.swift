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
            if let index = self.firstIndex(where: \.id == id) {
                if let newValue {
                    self[index] = newValue
                } else {
                    self.remove(at: index)
                }
            }
        }
    }
}

public extension Set where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? {
        get { first(where: \.id == id) }
        set {
            if let index = self.firstIndex(where: \.id == id) {
                self.remove(at: index)
                if let newValue {
                    self.insert(newValue)
                }
            }
        }
    }
}
