//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/20/23.
//
//

import Foundation
import SwiftUI

public extension Binding where Value: Equatable {
    func removeDuplicates(by isDuplicate: @escaping (Value, Value) -> Bool) -> Binding<Value> {
        .init {
            self.wrappedValue
        } set: { newValue, transaction in
            guard !isDuplicate(self.wrappedValue, newValue) else {
                return
            }
            self.transaction(transaction).wrappedValue = newValue
        }
    }

    func removeDuplicates() -> Binding<Value> {
        removeDuplicates(by: ==)
    }
}
