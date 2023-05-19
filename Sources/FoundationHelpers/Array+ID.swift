//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/11/23.
//  
//

import Foundation

extension Array where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? {
        get { self.first(where: \.id == id) }
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
